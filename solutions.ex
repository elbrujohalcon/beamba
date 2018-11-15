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
    case key_for(index, pos) do
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

  defp key_for(index, pos) when is_map(index), do: key_for(Map.to_list(index), pos)
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
