if Code.ensure_loaded?(Absinthe.Middleware) do
  defmodule Censor.AbsintheMiddleware do
    @moduledoc """
    Absinthe middleware for sensitive word checking.

    ## Usage

    In your Absinthe schema:

        field :create_post, :post do
          arg :title, non_null(:string)
          arg :content, non_null(:string)
          
          middleware Censor.AbsintheMiddleware, fields: [:title, :content]
          
          resolve &Resolvers.Posts.create/3
        end

    ## Options

    - `:fields` - List of argument fields to check (default: check all string args)
    - `:on_detect` - `:reject` (default) or `:replace`
    - `:replacement` - Replacement string (default: "***")

    """

    @behaviour Absinthe.Middleware

    def call(resolution, opts) do
      fields = Keyword.get(opts, :fields, :all)
      on_detect = Keyword.get(opts, :on_detect, :reject)
      replacement = Keyword.get(opts, :replacement, "***")

      args = resolution.arguments

      case check_arguments(args, fields) do
        :ok ->
          resolution

        {:error, field, words} ->
          handle_detection(resolution, field, words, on_detect, replacement)
      end
    end

    defp check_arguments(args, :all) do
      # Check all string arguments
      args
      |> Enum.filter(fn {_key, value} -> is_binary(value) end)
      |> Enum.reduce_while(:ok, fn {field, value}, :ok ->
        case Censor.check(value) do
          :ok ->
            {:cont, :ok}

          {:error, :sensitive_word_detected, info} ->
            {:halt, {:error, field, info.words}}
        end
      end)
    end

    defp check_arguments(args, fields) when is_list(fields) do
      Enum.find_value(fields, :ok, fn field ->
        value = Map.get(args, field)

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

    defp handle_detection(resolution, field, words, :reject, _replacement) do
      error_message = """
      Sensitive words detected in field '#{field}': #{Enum.join(words, ", ")}
      """

      Absinthe.Resolution.put_result(resolution, {:error, String.trim(error_message)})
    end

    defp handle_detection(resolution, _field, _words, :replace, replacement) do
      # Replace sensitive words in arguments
      new_args =
        Censor.replace_fields(
          resolution.arguments,
          Map.keys(resolution.arguments),
          replacement: replacement
        )

      %{resolution | arguments: new_args}
    end
  end
end
