defmodule Avatarex.Kitty do
  alias __MODULE__

  @base_dir "priv/sets/kitty"
  @enforce_keys [:body, :eye, :fur, :mouth, :accessory]
  @file_map Map.new(@enforce_keys, fn k -> {k, File.ls!("#{@base_dir}/#{k}/")} end)
  @count_map Map.new(@file_map, fn {k, v} -> {k, Enum.count(v)} end)
  @hash_parts div(128, Enum.count(@enforce_keys) + 1)
  @block_size div(512, @hash_parts)

  defstruct @enforce_keys

  def random() do
    Enum.reduce(@enforce_keys, %{}, fn field, acc -> 
      Map.put(acc, field, Enum.random(File.ls!("#{@base_dir}/#{field}/")))
    end)
    |> (&struct(Kitty, &1)).()
  end

  def generate(hash) when is_bitstring(hash) do
    @enforce_keys
    |> Enum.zip(for <<block::@block_size <- hash >>, do: block)
    |> Enum.map(fn {k, v} -> {k, rem(v, Map.get(@count_map, k))} end)
    |> Enum.map(fn {k, v} -> {k, Enum.fetch!(Map.get(@file_map, k), v)} end)
    |> Map.new()
    |> (&struct(Kitty, &1)).()
  end

  def render(%Kitty{} = kitty) do
    @enforce_keys
    |> Enum.map(&Image.open!("#{@base_dir}/#{&1}/#{Map.get(kitty, &1)}"))
    |> Enum.reduce(fn image, composite -> 
      Image.compose!(composite, image)
    end)
    |> Image.write!("priv/renders/#{:rand.uniform(24)}.png")
  end
end