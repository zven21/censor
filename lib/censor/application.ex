defmodule Censor.Application do
  @moduledoc """
  Censor Application module.

  This module handles the application startup and can optionally start
  Censor automatically if configured to do so.
  """

  use Application

  @impl true
  def start(_type, _args) do
    children = get_children()

    opts = [strategy: :one_for_one, name: Censor.AppSupervisor]
    Supervisor.start_link(children, opts)
  end

  @doc """
  Get the list of children to start based on configuration.
  """
  def get_children do
    case Censor.Config.get() do
      {:ok, config} ->
        if should_auto_start?(config) do
          [{Censor.Supervisor, config}]
        else
          []
        end

      {:error, reason} ->
        require Logger
        Logger.warning("Censor configuration error: #{inspect(reason)}")
        []
    end
  end

  # Private Functions

  defp should_auto_start?(config) do
    # Auto-start if words are provided or words_file is configured
    has_words = is_list(config[:words]) && length(config[:words]) > 0
    has_file = is_binary(config[:words_file]) && config[:words_file] != ""

    has_words || has_file
  end
end
