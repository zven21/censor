if Code.ensure_loaded?(Plug) do
  defmodule Censor.Plug do
    @moduledoc """
    Phoenix Plug for automatic sensitive word checking.

    ## Usage

    In your controller or router:

        plug Censor.Plug, fields: [:title, :content], on_detect: :reject
        
        # Or with custom handling
        plug Censor.Plug, 
          fields: [:title, :content],
          on_detect: :replace,
          replacement: "[filtered]"

    ## Options

    - `:fields` - List of param fields to check (required)
    - `:on_detect` - Action when detected: `:reject` (default), `:replace`, `:log`
    - `:replacement` - Replacement string when `on_detect: :replace` (default: "***")

    """

    import Plug.Conn

    def init(opts) do
      fields = Keyword.get(opts, :fields, [])
      on_detect = Keyword.get(opts, :on_detect, :reject)
      replacement = Keyword.get(opts, :replacement, "***")

      %{
        fields: fields,
        on_detect: on_detect,
        replacement: replacement
      }
    end

    def call(conn, %{fields: fields, on_detect: on_detect, replacement: replacement}) do
      params = conn.params

      case check_params(params, fields) do
        :ok ->
          conn

        {:error, field, words} ->
          handle_detection(conn, field, words, on_detect, replacement, params)
      end
    end

    defp check_params(params, fields) do
      Enum.find_value(fields, :ok, fn field ->
        value = get_param_value(params, field)

        if value && is_binary(value) do
          case Censor.check(value) do
            :ok ->
              nil

            {:error, :sensitive_word_detected, info} ->
              {:error, field, info.words}
          end
        end
      end)
    end

    defp handle_detection(conn, field, words, :reject, _replacement, _params) do
      conn
      |> put_status(:bad_request)
      |> put_resp_content_type("application/json")
      |> send_resp(
        400,
        Jason.encode!(%{
          error: "Sensitive words detected",
          field: field,
          words: words
        })
      )
      |> halt()
    end

    defp handle_detection(conn, field, _words, :replace, replacement, params) do
      # Replace sensitive words in params
      new_params = Censor.replace_fields(params, [field], replacement: replacement)
      %{conn | params: new_params}
    end

    defp handle_detection(conn, field, words, :log, _replacement, _params) do
      require Logger
      Logger.warning("Sensitive words detected in #{field}: #{inspect(words)}")
      conn
    end

    defp get_param_value(params, field) when is_atom(field) do
      params[field] || params[to_string(field)]
    end

    defp get_param_value(params, field) when is_binary(field) do
      params[field] || params[String.to_atom(field)]
    end
  end
end
