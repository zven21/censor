defmodule Censor.Loader do
  @moduledoc """
  Word list loader and manager.

  Handles loading words from file or list, and maintains them in cache.
  """

  use GenServer
  require Logger

  @cache_name :censor_words_cache

  # Client API

  @doc """
  Start the loader.
  """
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Reload word list from source.
  """
  def reload do
    GenServer.call(__MODULE__, :reload)
  end

  @doc """
  Get statistics about current word list.
  """
  def stats do
    GenServer.call(__MODULE__, :stats)
  end

  @doc """
  Add new words to the list.
  """
  def add_words(words) when is_list(words) do
    GenServer.call(__MODULE__, {:add_words, words})
  end

  @doc """
  Remove words from the list.
  """
  def remove_words(words) when is_list(words) do
    GenServer.call(__MODULE__, {:remove_words, words})
  end

  # Server Callbacks

  @impl true
  def init(opts) do
    # Initialize cache (only if not already started)
    case Cachex.start_link(@cache_name) do
      {:ok, _} -> :ok
      {:error, {:already_started, _}} -> :ok
    end

    state = %{
      words_file: Keyword.get(opts, :words_file),
      words: Keyword.get(opts, :words, []),
      auto_reload: Keyword.get(opts, :auto_reload, false),
      reload_interval: Keyword.get(opts, :reload_interval, 5000),
      last_updated: nil,
      file_mtime: nil
    }

    # Initial load
    {:ok, state} = load_words(state)

    # Schedule reload if auto_reload enabled
    if state.auto_reload && state.words_file do
      schedule_reload(state.reload_interval)
    end

    Logger.info("🛡️  Censor started with #{length(state.words)} words")

    {:ok, state}
  end

  @impl true
  def handle_call(:reload, _from, state) do
    case load_words(state) do
      {:ok, new_state} ->
        Logger.info("🔄 Censor reloaded: #{length(new_state.words)} words")
        {:reply, {:ok, %{loaded: length(new_state.words)}}, new_state}

      {:error, reason} ->
        Logger.error("❌ Censor reload failed: #{inspect(reason)}")
        {:reply, {:error, reason}, state}
    end
  end

  @impl true
  def handle_call(:stats, _from, state) do
    stats = %{
      total: length(state.words),
      last_updated: state.last_updated,
      source: if(state.words_file, do: :file, else: :list)
    }

    {:reply, stats, state}
  end

  @impl true
  def handle_call({:add_words, new_words}, _from, state) do
    current_words = state.words
    all_words = (current_words ++ new_words) |> Enum.uniq()

    added = length(all_words) - length(current_words)

    new_state = %{state | words: all_words, last_updated: DateTime.utc_now()}

    update_cache(all_words)

    Logger.info("➕ Censor: Added #{added} words, total: #{length(all_words)}")

    {:reply, {:ok, %{added: added, total: length(all_words)}}, new_state}
  end

  @impl true
  def handle_call({:remove_words, words_to_remove}, _from, state) do
    current_words = state.words
    remaining_words = Enum.reject(current_words, &(&1 in words_to_remove))

    removed = length(current_words) - length(remaining_words)

    new_state = %{state | words: remaining_words, last_updated: DateTime.utc_now()}

    update_cache(remaining_words)

    Logger.info("➖ Censor: Removed #{removed} words, total: #{length(remaining_words)}")

    {:reply, {:ok, %{removed: removed, total: length(remaining_words)}}, new_state}
  end

  @impl true
  def handle_info(:check_reload, state) do
    new_state =
      if should_reload?(state) do
        case load_words(state) do
          {:ok, new_state} ->
            Logger.info("🔄 Censor auto-reloaded: #{length(new_state.words)} words")
            new_state

          {:error, _reason} ->
            state
        end
      else
        state
      end

    # Schedule next check
    schedule_reload(state.reload_interval)

    {:noreply, new_state}
  end

  # Private Functions

  defp load_words(state) do
    words =
      cond do
        state.words_file && File.exists?(state.words_file) ->
          load_from_file(state.words_file)

        is_list(state.words) && length(state.words) > 0 ->
          state.words

        true ->
          []
      end

    file_mtime =
      if state.words_file && File.exists?(state.words_file) do
        File.stat!(state.words_file).mtime
      else
        nil
      end

    # Update cache
    update_cache(words)

    new_state = %{state | words: words, last_updated: DateTime.utc_now(), file_mtime: file_mtime}

    {:ok, new_state}
  end

  defp load_from_file(file_path) do
    file_path
    |> File.read!()
    |> String.split("\n", trim: true)
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == "" || String.starts_with?(&1, "#")))
    |> Enum.uniq()
  end

  defp update_cache(words) do
    Cachex.put(@cache_name, "words", words)
  end

  defp should_reload?(%{words_file: nil}), do: false

  defp should_reload?(%{words_file: file_path, file_mtime: old_mtime}) do
    if File.exists?(file_path) do
      new_mtime = File.stat!(file_path).mtime
      old_mtime != new_mtime
    else
      false
    end
  end

  defp schedule_reload(interval) do
    Process.send_after(self(), :check_reload, interval)
  end
end
