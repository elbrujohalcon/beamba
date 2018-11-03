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

## This doesn't work because it doesn't preserve the order
# defmodule BeamBA.Uniq do
#   def run([]), do: []

#   def run([elem | rest]) do
#     rec = run(rest)
#     if member?(rec, elem) do
#       rec
#     else
#       [elem | rec]
#     end
#   end

#   def member?([], _elem), do: false
#   def member?([elem | _rest], elem), do: true
#   def member?([_not_elem | rest], elem), do: member?(rest, elem)
# end

## This is the original version
# defmodule BeamBA.Uniq do
#   def run([]), do: []

#   def run([elem | rest]) do
#     [elem | run(remove(rest, elem))]
#   end

#   defp remove([], _elem), do: []
#   defp remove([elem | rest], elem), do: remove(rest, elem)
#   defp remove([not_elem | rest], elem), do: [not_elem | remove(rest, elem)]
# end

## This version doesn't use Index.map
# defmodule BeamBA.Uniq do
#   def run(list) do
#     list
#     |> BeamBA.Index.pack()
#     |> Map.to_list()
#     |> keep_first_pos
#     |> Map.new()
#     |> BeamBA.Index.unpack()
#   end

#   defp keep_first_pos([]), do: []
#   defp keep_first_pos([{elem, [pos | _]} | rest]), do: [{elem, [pos]} | keep_first_pos(rest)]
# end

## This is the final version
defmodule BeamBA.Uniq do
  def run(list) do
    list
    |> BeamBA.Index.pack()
    |> BeamBA.Index.map(&keep_first_pos/2)
    |> BeamBA.Index.unpack()
  end

  defp keep_first_pos(elem, [pos | _]), do: [pos]
end

defmodule BeamBA.Index do
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

  We accept corrupt indexes (without some positions) to allow for special operations (see above)
  """
  def unpack(map), do: unpack(map, 1)

  defp unpack(index, _pos) when map_size(index) == 0, do: []

  defp unpack(index, pos) do
    case key_for(Map.to_list(index), pos) do
      :not_found -> unpack(index, pos + 1)
      elem -> [elem | unpack(remove(index, elem, pos), pos + 1)]
    end
  end

  defp remove(index, elem, pos) do
    case index do
      %{^elem => [^pos]} -> Map.delete(index, elem)
      %{^elem => [^pos | others]} -> Map.replace!(index, elem, others)
    end
  end

  defp key_for([], _pos), do: :not_found
  defp key_for([{elem, [pos | _]} | _rest], pos), do: elem
  defp key_for([_ | rest], pos), do: key_for(rest, pos)

  ## The following functions should not be part of the initial setup (follow plan.md)
  def map(index, fun) do
    index |> Map.to_list() |> map_on_list(fun) |> Map.new()
  end

  defp map_on_list([], _fun), do: []

  defp map_on_list([{elem, positions} | rest], fun) do
    [{elem, fun.(elem, positions)} | map_on_list(rest, fun)]
  end
end
