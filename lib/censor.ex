defmodule Censor do
  @moduledoc """
  High-performance sensitive word filtering for Elixir applications.

  Censor provides fast, flexible sensitive word detection and filtering using
  a DFA (Deterministic Finite Automaton) algorithm with hot-reload support.

  ## Features

  - 🚀 **High Performance** - DFA algorithm with microsecond-level speed
  - 📝 **Multiple Modes** - Detect, replace, highlight, extract
  - 🔄 **Hot Reload** - Update word list without restart
  - 🌐 **Multi-Language** - Support Chinese, English, and more
  - 🎯 **Flexible** - Custom replacement strategies

  ## Quick Start

      # Start Censor
      {:ok, _pid} = Censor.start_link(
        words: ["badword1", "badword2"],
        auto_reload: true
      )
      
      # Check text
      case Censor.check("text with badword1") do
        :ok -> 
          IO.puts("✅ Clean")
        {:error, :sensitive_word_detected, %{words: words}} -> 
          IO.puts("❌ Found: " <> inspect(words))
      end
      
      # Replace sensitive words
      clean = Censor.replace("text with badword1", replacement: "***")
      #=> "text with ***"

  """

  alias Censor.{Checker, Loader}

  @doc """
  Start Censor with the given options.

  ## Options

  - `:words` - List of sensitive words (default: [])
  - `:words_file` - Path to word list file (default: nil)
  - `:auto_reload` - Enable file watching (default: false)
  - `:reload_interval` - Check interval in ms (default: 5000)
  - `:case_sensitive` - Case sensitive matching (default: false)

  ## Examples

      # From list
      Censor.start_link(words: ["bad", "evil"])
      
      # From file with hot reload
      Censor.start_link(
        words_file: "priv/sensitive_words.txt",
        auto_reload: true
      )

  """
  def start_link(opts \\ []) do
    Censor.Supervisor.start_link(opts)
  end

  @doc """
  Check if text contains sensitive words.

  ## Returns

  - `:ok` - Text is clean
  - `{:error, :sensitive_word_detected, info}` - Contains sensitive words

  ## Examples

      iex> Censor.check("clean text")
      :ok
      
      iex> Censor.check("text with badword")
      {:error, :sensitive_word_detected, %{words: ["badword"], count: 1}}

  """
  defdelegate check(text), to: Checker

  @doc """
  Check if text contains sensitive words (boolean return).

  ## Examples

      iex> Censor.contains?("clean text")
      false
      
      iex> Censor.contains?("text with badword")
      true

  """
  defdelegate contains?(text), to: Checker

  @doc """
  Find all sensitive words in text.

  ## Returns

  List of sensitive words found.
  """
  defdelegate find_all(text), to: Checker

  @doc """
  Replace sensitive words in text.

  ## Options

  - `:replacement` - Replacement string or function (default: "***")

  ## Examples

      iex> Censor.replace("text with badword", replacement: "***")
      "text with ***"
      
      iex> Censor.replace("badword", replacement: fn word -> 
      ...>   String.duplicate("*", String.length(word))
      ...> end)
      "*******"

  """
  defdelegate replace(text, opts \\ []), to: Checker

  @doc """
  Highlight sensitive words in text (wrap with HTML mark tag).

  ## Examples

      iex> Censor.highlight("text with badword")
      "text with <mark>badword</mark>"

  """
  defdelegate highlight(text), to: Checker

  @doc """
  Check multiple fields in a map for sensitive words.
  """
  defdelegate check_fields(data, fields), to: Checker

  @doc """
  Replace sensitive words in multiple fields of a map.

  ## Examples

      iex> Censor.replace_fields(%{name: "badword", memo: "clean"}, [:name, :memo])
      %{name: "***", memo: "clean"}

  """
  defdelegate replace_fields(data, fields, opts \\ []), to: Checker

  @doc """
  Reload word list from source.
  """
  def reload do
    Loader.reload()
  end

  @doc """
  Get current word list statistics.
  """
  def stats do
    Loader.stats()
  end

  @doc """
  Add words to the current list.
  """
  def add_words(words) when is_list(words) do
    Loader.add_words(words)
  end

  @doc """
  Remove words from the current list.
  """
  def remove_words(words) when is_list(words) do
    Loader.remove_words(words)
  end
end
