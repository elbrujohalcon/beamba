defmodule BeamBA.Index do
  alias __MODULE__

  defp assert_up(input) do
    ^input = input |> Index.unpack() |> Index.pack()
  end

  defp assert_pu(input) do
    ^input = input |> Index.pack() |> Index.unpack()
  end

  def test do
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

  @doc """
  This is the easiest form of recursion.
  The only trick is to have an auxiliary function.
  In it, for each element in the list, we update the index accordingly.
  """
  def pack(list), do: pack(list, 1)

  defp pack([], _pos), do: %{}

  defp pack([elem | rest], pos) do
    Map.update(pack(rest, pos + 1), elem, [pos], &[pos | &1])
  end

  @doc """
  This is more complex.
  We also have an auxiliary function, but now have to traverse the index many times.
  This function should not be used for anything other than tests.
  The interesting recursion part is &key_for/2
  """
  def unpack(map), do: unpack(map, 1)

  defp unpack(index, _pos) when map_size(index) == 0, do: []

  defp unpack(index, pos) do
    elem = key_for(Map.to_list(index), pos)

    rest =
      case index do
        %{^elem => [^pos]} -> Map.delete(index, elem)
        %{^elem => [^pos | others]} -> Map.replace!(index, elem, others)
      end

    [elem | unpack(rest, pos + 1)]
  end

  @doc """
  This function uses pattern-matching smartly in its clause heads to find the first
  element with the corresponding position, knowing that the positions are sorted.
  And it has no base case => Let it crash!
  """
  # defp key_for([], pos), do: raise "position not found: #{pos}"
  defp key_for([{elem, [pos | _]} | _rest], pos), do: elem
  defp key_for([_ | rest], pos), do: key_for(rest, pos)
end
