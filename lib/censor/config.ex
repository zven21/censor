defmodule Censor.Config do
  @moduledoc """
  Configuration management for Censor.

  This module handles configuration loading from application config,
  environment variables, and runtime options.
  """

  @doc """
  Get the configuration for Censor.

  Configuration can be set in several ways:

  1. Application config (config/config.exs):
     ```elixir
     config :censor,
       words: ["badword1", "badword2"],
       words_file: "priv/sensitive_words.txt",
       auto_reload: true,
       case_sensitive: false,
       replacement: "***"
     ```

  2. Environment variables:
     - `CENSOR_WORDS_FILE` - Path to words file
     - `CENSOR_AUTO_RELOAD` - Enable auto reload (true/false)
     - `CENSOR_CASE_SENSITIVE` - Case sensitive matching (true/false)
     - `CENSOR_REPLACEMENT` - Default replacement string

  3. Runtime options (passed to Censor.start_link/1)

  ## Options

  - `:words` - List of sensitive words (default: [])
  - `:words_file` - Path to words file (default: nil)
  - `:auto_reload` - Enable file watching (default: false)
  - `:reload_interval` - Check interval in ms (default: 5000)
  - `:case_sensitive` - Case sensitive matching (default: false)
  - `:replacement` - Default replacement string (default: "***")
  - `:detection_mode` - Detection mode: :detect, :replace, :highlight (default: :detect)
  - `:cache_ttl` - Cache TTL in seconds (default: 3600)
  """
  def get(opts \\ []) do
    default_config()
    |> merge_app_config()
    |> merge_env_config()
    |> merge_runtime_opts(opts)
    |> validate_config()
  end

  @doc """
  Get a specific configuration value.
  """
  def get(key, opts) do
    case get(opts) do
      {:ok, config} -> Map.get(config, key)
      {:error, _reason} -> nil
    end
  end

  @doc """
  Check if configuration is valid.
  """
  def valid?(opts \\ []) do
    case get(opts) do
      {:ok, _config} -> true
      {:error, _reason} -> false
    end
  end

  # Private Functions

  defp default_config do
    %{
      words: [],
      words_file: nil,
      auto_reload: false,
      reload_interval: 5000,
      case_sensitive: false,
      replacement: "***",
      detection_mode: :detect,
      cache_ttl: 3600
    }
  end

  defp merge_app_config(config) do
    app_config = Application.get_env(:censor, :config, [])

    Enum.reduce(app_config, config, fn {key, value}, acc ->
      Map.put(acc, key, value)
    end)
  end

  defp merge_env_config(config) do
    config
    |> put_env_value(:words_file, "CENSOR_WORDS_FILE")
    |> put_env_value(:auto_reload, "CENSOR_AUTO_RELOAD", &parse_boolean/1)
    |> put_env_value(:case_sensitive, "CENSOR_CASE_SENSITIVE", &parse_boolean/1)
    |> put_env_value(:replacement, "CENSOR_REPLACEMENT")
    |> put_env_value(:reload_interval, "CENSOR_RELOAD_INTERVAL", &parse_integer/1)
    |> put_env_value(:cache_ttl, "CENSOR_CACHE_TTL", &parse_integer/1)
  end

  defp merge_runtime_opts(config, opts) do
    Enum.reduce(opts, config, fn {key, value}, acc ->
      Map.put(acc, key, value)
    end)
  end

  defp put_env_value(config, key, env_var, parser \\ & &1) do
    case System.get_env(env_var) do
      nil -> config
      value -> Map.put(config, key, parser.(value))
    end
  end

  defp parse_boolean("true"), do: true
  defp parse_boolean("false"), do: false
  defp parse_boolean("1"), do: true
  defp parse_boolean("0"), do: false
  defp parse_boolean(_), do: false

  defp parse_integer(value) do
    case Integer.parse(value) do
      {int, ""} -> int
      _ -> nil
    end
  end

  defp validate_config(config) do
    with :ok <- validate_words(config),
         :ok <- validate_file(config),
         :ok <- validate_intervals(config),
         :ok <- validate_modes(config) do
      {:ok, config}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  defp validate_words(%{words: words}) when is_list(words), do: :ok

  defp validate_words(%{words: words}),
    do: {:error, "words must be a list, got: #{inspect(words)}"}

  defp validate_file(%{words_file: nil}), do: :ok

  defp validate_file(%{words_file: file_path}) when is_binary(file_path) do
    if File.exists?(file_path) do
      :ok
    else
      {:error, "words file does not exist: #{file_path}"}
    end
  end

  defp validate_file(%{words_file: file_path}),
    do: {:error, "words_file must be a string, got: #{inspect(file_path)}"}

  defp validate_intervals(config) do
    with :ok <- validate_reload_interval(config),
         :ok <- validate_cache_ttl(config) do
      :ok
    end
  end

  defp validate_reload_interval(%{reload_interval: interval})
       when is_integer(interval) and interval > 0,
       do: :ok

  defp validate_reload_interval(%{reload_interval: interval}),
    do: {:error, "reload_interval must be a positive integer, got: #{inspect(interval)}"}

  defp validate_cache_ttl(%{cache_ttl: ttl}) when is_integer(ttl) and ttl > 0, do: :ok

  defp validate_cache_ttl(%{cache_ttl: ttl}),
    do: {:error, "cache_ttl must be a positive integer, got: #{inspect(ttl)}"}

  defp validate_modes(%{detection_mode: mode}) when mode in [:detect, :replace, :highlight],
    do: :ok

  defp validate_modes(%{detection_mode: mode}),
    do:
      {:error,
       "detection_mode must be one of [:detect, :replace, :highlight], got: #{inspect(mode)}"}
end
