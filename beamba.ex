defmodule BeamBA.Test do
  alias BeamBA.Index
  alias BeamBA.Uniq

  defp assert_up(input) do
    ^input = input |> Index.unpack() |> Index.pack()
  end

  defp assert_pu(input) do
    ^input = input |> Index.pack() |> Index.unpack()
  end

  def run do
    [
      &test_uniq/0,
      &test_pack/0
    ]
    |> Enum.each(& &1.())
  end

  defp test_uniq do
    [] = Uniq.run([])
    [1] = Uniq.run([1])
    [1] = Uniq.run([1, 1, 1])
    [1, 2] = Uniq.run([1, 2, 1, 1, 2])
    [:a, :c, :b] = Uniq.run([:a, :a, :c, :b, :a, :c])
  end

  defp test_pack do
    %{} = Index.pack([])
    %{:a => [1]} = Index.pack([:a])
    %{:a => [1, 2, 3]} = Index.pack([:a, :a, :a])
    %{:a => [1], :b => [2]} = Index.pack([:a, :b])
    %{:a => [2], :b => [1]} = Index.pack([:b, :a])
    %{:a => [2], :b => [1, 3]} = Index.pack([:b, :a, :b])
    %{:a => [2], :b => [1, 4], :c => [3]} = Index.pack([:b, :a, :c, :b])

    [
      [],
      [1],
      [1, 1],
      [1, 2, 1],
      'The quick brown fox jumps over the lazy dog.',
      ["The", "quick", "brown", "fox", "jumps", "over", "the", "lazy", "dog"]
    ]
    |> Enum.each(&assert_pu/1)

    [
      %{},
      %{1 => [1]},
      %{1 => [1], 2 => [2]},
      %{1 => [1, 2]},
      %{1 => [1, 3], 2 => [2]}
    ]
    |> Enum.each(&assert_up/1)
  end
end
