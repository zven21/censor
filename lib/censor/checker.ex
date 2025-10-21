defmodule Censor.Checker do
  @moduledoc """
  Core checking and filtering logic for Censor.

  Uses a cache-based approach for high performance.
  """

  @cache_name :censor_words_cache

  @doc """
  Check if text contains sensitive words.

  ## Returns

  - `:ok` - Text is clean
  - `{:error, :sensitive_word_detected, info}` - Contains sensitive words
  """
  def check(nil), do: :ok
  def check(""), do: :ok
  def check(text) when not is_binary(text), do: :ok

  def check(text) when is_binary(text) do
    case find_all(text) do
      [] ->
        :ok

      words ->
        {:error, :sensitive_word_detected,
         %{
           words: words,
           count: length(words)
         }}
    end
  end

  @doc """
  Check if text contains sensitive words (boolean).
  """
  def contains?(text) do
    case check(text) do
      :ok -> false
      {:error, :sensitive_word_detected, _} -> true
    end
  end

  @doc """
  Find all sensitive words in text.

  Returns a list of detected sensitive words.
  """
  def find_all(nil), do: []
  def find_all(""), do: []

  def find_all(text) when is_binary(text) do
    words = get_word_list()
    normalized_text = String.downcase(text)

    words
    |> Enum.filter(fn word ->
      normalized_word = String.downcase(word)
      String.contains?(normalized_text, normalized_word)
    end)
    |> Enum.uniq()
  end

  @doc """
  Replace sensitive words in text.

  ## Options

  - `:replacement` - Replacement string or function (default: "***")

  ## Examples

      # Simple replacement
      replace("bad text", replacement: "***")
      #=> "*** text"
      
      # Function replacement (match word length)
      replace("bad text", replacement: fn word -> 
        String.duplicate("*", String.length(word))
      end)
      #=> "*** text"
  """
  def replace(text, opts \\ [])
  def replace(nil, _opts), do: nil
  def replace("", _opts), do: ""

  def replace(text, opts) when is_binary(text) do
    words = get_word_list()
    replacement = Keyword.get(opts, :replacement, "***")

    Enum.reduce(words, text, fn word, acc ->
      replace_word(acc, word, replacement)
    end)
  end

  defp replace_word(text, word, replacement) when is_binary(replacement) do
    String.replace(text, word, replacement, case_insensitive: true)
  end

  defp replace_word(text, word, replacement) when is_function(replacement, 1) do
    String.replace(text, word, replacement.(word), case_insensitive: true)
  end

  @doc """
  Highlight sensitive words with HTML mark tags.

  ## Examples

      highlight("text with badword")
      #=> "text with <mark>badword</mark>"
  """
  def highlight(nil), do: nil
  def highlight(""), do: ""

  def highlight(text) when is_binary(text) do
    words = get_word_list()

    Enum.reduce(words, text, fn word, acc ->
      # Case insensitive replacement with original case preserved
      regex = Regex.compile!(Regex.escape(word), "i")

      String.replace(acc, regex, fn matched ->
        "<mark>#{matched}</mark>"
      end)
    end)
  end

  @doc """
  Check multiple fields in a map.

  ## Examples

      check_fields(%{name: "clean", desc: "also clean"}, [:name, :desc])
      #=> :ok
      
      check_fields(%{name: "has badword"}, [:name])
      #=> {:error, :sensitive_word_detected, %{field: :name, words: ["badword"]}}
  """
  def check_fields(data, fields) when is_map(data) and is_list(fields) do
    result =
      Enum.find_value(fields, fn field ->
        value = get_field_value(data, field)

        case check(value) do
          :ok ->
            nil

          {:error, :sensitive_word_detected, info} ->
            {field, info.words}
        end
      end)

    case result do
      nil ->
        :ok

      {field, words} ->
        {:error, :sensitive_word_detected,
         %{
           field: field,
           words: words,
           count: length(words)
         }}
    end
  end

  @doc """
  Replace sensitive words in multiple fields of a map.

  ## Examples

      replace_fields(%{name: "badword", memo: "clean"}, [:name, :memo])
      #=> %{name: "***", memo: "clean"}
  """
  def replace_fields(data, fields, opts \\ []) when is_map(data) and is_list(fields) do
    replacement = Keyword.get(opts, :replacement, "***")

    Enum.reduce(fields, data, fn field, acc ->
      value = get_field_value(acc, field)

      if value && is_binary(value) do
        filtered_value = replace(value, replacement: replacement)
        put_field_value(acc, field, filtered_value)
      else
        acc
      end
    end)
  end

  # Private Functions

  defp get_word_list do
    case Cachex.get(@cache_name, "words") do
      {:ok, words} when is_list(words) ->
        # Filter out empty strings
        Enum.filter(words, &(String.trim(&1) != ""))

      _ ->
        # If cache not initialized, return empty list
        []
    end
  end

  defp get_field_value(map, field) do
    Map.get(map, field) || Map.get(map, to_string(field))
  end

  defp put_field_value(map, field, value) do
    cond do
      Map.has_key?(map, field) ->
        Map.put(map, field, value)

      Map.has_key?(map, to_string(field)) ->
        Map.put(map, to_string(field), value)

      true ->
        map
    end
  end
end
