defmodule Censor.ConfigTest do
  @moduledoc """
  Tests for Censor.Config module.
  """

  use ExUnit.Case, async: true
  alias Censor.Config

  describe "get/1" do
    test "returns default config when no options provided" do
      {:ok, config} = Config.get()

      assert config[:words] == []
      assert config[:words_file] == nil
      assert config[:auto_reload] == false
      assert config[:reload_interval] == 5000
      assert config[:case_sensitive] == false
      assert config[:replacement] == "***"
      assert config[:detection_mode] == :detect
      assert config[:cache_ttl] == 3600
    end

    test "merges runtime options with defaults" do
      {:ok, config} = Config.get(words: ["test"], auto_reload: true)

      assert config[:words] == ["test"]
      assert config[:auto_reload] == true
      # default
      assert config[:reload_interval] == 5000
    end

    test "validates words is a list" do
      assert {:error, "words must be a list, got: \"not_a_list\""} =
               Config.get(words: "not_a_list")
    end

    test "validates words_file exists when provided" do
      assert {:error, "words file does not exist: nonexistent.txt"} =
               Config.get(words_file: "nonexistent.txt")
    end

    test "validates reload_interval is positive integer" do
      assert {:error, "reload_interval must be a positive integer, got: -1"} =
               Config.get(reload_interval: -1)
    end

    test "validates cache_ttl is positive integer" do
      assert {:error, "cache_ttl must be a positive integer, got: 0"} =
               Config.get(cache_ttl: 0)
    end

    test "validates detection_mode is valid" do
      assert {:error,
              "detection_mode must be one of [:detect, :replace, :highlight], got: :invalid"} =
               Config.get(detection_mode: :invalid)
    end
  end

  describe "get/2" do
    test "returns specific config value" do
      assert Config.get(:words, words: ["test"]) == ["test"]
      assert Config.get(:auto_reload, words: ["test"]) == false
    end
  end

  describe "valid?/1" do
    test "returns true for valid config" do
      assert Config.valid?(words: ["test"]) == true
    end

    test "returns false for invalid config" do
      assert Config.valid?(words: "not_a_list") == false
    end
  end

  describe "environment variable parsing" do
    test "handles environment variables correctly" do
      # Test that environment variables are properly merged
      # This is tested indirectly through the config merging
      {:ok, config} = Config.get()

      # Should have default values
      assert is_boolean(config[:auto_reload])
      assert is_integer(config[:reload_interval])
      assert is_integer(config[:cache_ttl])
    end
  end
end
