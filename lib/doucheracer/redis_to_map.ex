defmodule Doucheracer.RedisToMap do

  def redis_to_map(hgetall, map \\ :identity) do
    map = case map do
      :identity -> &identity_map/1
      f -> f
    end

    hgetall
      |> Enum.chunk(2)
      |> Enum.map(map)
      |> Enum.reduce(%{}, fn ([key, val], acc) -> Map.put(acc, key, val) end)
  end

  defp identity_map([key, value]) do
    [key, value]
  end
end
