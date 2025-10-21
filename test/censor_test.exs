defmodule CensorTest do
  use ExUnit.Case
  doctest Censor

  setup do
    # Stop existing Censor if running
    case Process.whereis(Censor.Supervisor) do
      nil ->
        :ok

      pid when is_pid(pid) ->
        try do
          Supervisor.stop(pid, :normal, 100)
        catch
          :exit, _ -> :ok
        end
    end

    # Small delay to ensure cleanup
    Process.sleep(10)

    # Start Censor with test words
    {:ok, _pid} = Censor.start_link(words: ["badword", "evil", "敏感词", "违禁"])

    :ok
  end

  describe "check/1" do
    test "returns :ok for clean text" do
      assert :ok == Censor.check("This is clean text")
      assert :ok == Censor.check("这是干净的文本")
    end

    test "detects English sensitive words" do
      assert {:error, :sensitive_word_detected, info} = Censor.check("This has badword")
      assert "badword" in info.words
      assert info.count == 1
    end

    test "detects Chinese sensitive words" do
      assert {:error, :sensitive_word_detected, info} = Censor.check("包含敏感词")
      assert "敏感词" in info.words
    end

    test "detects multiple sensitive words" do
      assert {:error, :sensitive_word_detected, info} =
               Censor.check("badword and evil words here")

      assert length(info.words) == 2
      assert "badword" in info.words
      assert "evil" in info.words
    end

    test "is case insensitive" do
      assert {:error, :sensitive_word_detected, _} = Censor.check("BADWORD")
      assert {:error, :sensitive_word_detected, _} = Censor.check("BadWord")
    end

    test "handles nil and empty string" do
      assert :ok == Censor.check(nil)
      assert :ok == Censor.check("")
    end
  end

  describe "contains?/1" do
    test "returns false for clean text" do
      refute Censor.contains?("clean text")
    end

    test "returns true for sensitive text" do
      assert Censor.contains?("has badword")
    end
  end

  describe "find_all/1" do
    test "returns empty list for clean text" do
      assert [] == Censor.find_all("clean text")
    end

    test "returns list of sensitive words" do
      words = Censor.find_all("badword and evil")
      assert length(words) == 2
      assert "badword" in words
      assert "evil" in words
    end

    test "returns unique words only" do
      words = Censor.find_all("badword and badword again")
      assert "badword" in words
      assert length(words) == 1
    end
  end

  describe "replace/2" do
    test "replaces with default ***" do
      assert "This is ***" == Censor.replace("This is badword")
    end

    test "replaces with custom string" do
      result = Censor.replace("This is badword", replacement: "[filtered]")
      assert result == "This is [filtered]"
    end

    test "replaces with function" do
      result =
        Censor.replace("badword",
          replacement: fn word ->
            String.duplicate("*", String.length(word))
          end
        )

      assert result == "*******"
    end

    test "replaces multiple occurrences" do
      result = Censor.replace("badword and evil words")
      assert result == "*** and *** words"
    end

    test "handles Chinese" do
      result = Censor.replace("包含敏感词的文本")
      assert result == "包含***的文本"
    end

    test "handles nil and empty" do
      assert nil == Censor.replace(nil)
      assert "" == Censor.replace("")
    end
  end

  describe "highlight/1" do
    test "wraps sensitive words with mark tags" do
      result = Censor.highlight("text with badword")
      assert result == "text with <mark>badword</mark>"
    end

    test "preserves original case" do
      result = Censor.highlight("BADWORD and BadWord")
      assert result == "<mark>BADWORD</mark> and <mark>BadWord</mark>"
    end

    test "handles multiple words" do
      result = Censor.highlight("badword and evil")
      assert String.contains?(result, "<mark>badword</mark>")
      assert String.contains?(result, "<mark>evil</mark>")
    end
  end

  describe "check_fields/2" do
    test "returns :ok when all fields are clean" do
      data = %{name: "clean", description: "also clean"}
      assert :ok == Censor.check_fields(data, [:name, :description])
    end

    test "detects sensitive word in specific field" do
      data = %{name: "has badword", description: "clean"}

      assert {:error, :sensitive_word_detected, info} =
               Censor.check_fields(data, [:name, :description])

      assert info.field == :name
      assert "badword" in info.words
    end

    test "works with string keys" do
      data = %{"name" => "has badword", "desc" => "clean"}

      assert {:error, :sensitive_word_detected, info} =
               Censor.check_fields(data, [:name, :desc])

      assert info.field == :name
    end

    test "handles nil and non-string values" do
      data = %{name: nil, count: 123, desc: "clean"}
      assert :ok == Censor.check_fields(data, [:name, :count, :desc])
    end
  end

  describe "replace_fields/3" do
    test "replaces sensitive words in specified fields" do
      data = %{name: "badword name", memo: "evil memo", count: 10}
      result = Censor.replace_fields(data, [:name, :memo])

      assert result.name == "*** name"
      assert result.memo == "*** memo"
      assert result.count == 10
    end

    test "preserves key types (atom vs string)" do
      # Test atom keys
      data1 = %{name: "badword", memo: "evil"}
      result1 = Censor.replace_fields(data1, [:name, :memo])
      assert result1.name == "***"
      assert result1.memo == "***"

      # Test string keys
      data2 = %{"name" => "badword", "memo" => "evil"}
      result2 = Censor.replace_fields(data2, [:name, :memo])
      assert result2["name"] == "***"
      assert result2["memo"] == "***"
    end

    test "handles nil values" do
      data = %{name: nil, memo: "badword"}
      result = Censor.replace_fields(data, [:name, :memo])

      assert result.name == nil
      assert result.memo == "***"
    end
  end
end
