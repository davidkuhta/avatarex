defmodule AvatarexSet do
  @moduledoc """
  This module provides functions for creating an `AvatarexSet`
  """

  @doc """
  Generates all functions for generating `AvatarexSet`s and associated renders

  Required opts:
  	dir: "/path/to/my_set"
  	keys: [:field1, :field2, :field3]

  `dir` corresponding to folders ex: `"/path/to/my_set/field1"`

  `keys` correspond to folders under the provided `dir`, ex: `"/path/to/my_set/field1"`
  `keys` ordering will correspond to the order in images will be layered. `[:base_layer, :next_layer, ...]`

  ## Examples
      iex> use #{__MODULE__}, dir: "/path/to/my_set", keys: [:field1, :field2, :field3] 

  """
  defmacro __using__(opts) do
    caller = __CALLER__.module

  	dir = case Keyword.get(opts, :dir) do
  		nil -> raise ArgumentError, ":dir option required \n 'path/to/set'"
  		dir -> dir
  	end

  	dir_fields = case File.ls(dir) do
  		{:error, _error} -> raise "Directory doesn't exist"
  		{:ok, files} -> files
  	end

  	keys = case Keyword.get(opts, :keys) do
  		nil -> raise ArgumentError, ":keys option required \n [:field1, :field2, ...]"
  		keys -> keys
  	end

  	for field <- keys do
  		if !Enum.member?(dir_fields, to_string(field)), 
  			do: raise ArgumentError, "#{field}/ folder not found in #{dir}"
  	end

  	output_dir = case Keyword.get(opts, :output_dir) do
  		nil -> "priv/renders"
  		dir -> dir
  	end

	file_map = Map.new(keys, fn k -> {k, File.ls!("#{dir}/#{k}/")} end)
	count_map = Map.new(file_map, fn {k, v} -> {k, Enum.count(v)} end)
	hash_parts = div(128, Enum.count(keys) + 1)
	block_size = div(512, hash_parts)

    # Define the attribute and set it in the calling module
    Module.register_attribute(caller, :base_dir, accumulate: false)
    Module.put_attribute(caller, :base_dir, dir)
    Module.register_attribute(caller, :enforce_keys, accumulate: false)
    Module.put_attribute(caller, :enforce_keys, keys)
    Module.register_attribute(caller, :output_dir, accumulate: false)
    Module.put_attribute(caller, :output_dir, output_dir)
    Module.register_attribute(caller, :file_map, accumulate: false)
    Module.put_attribute(caller, :file_map, file_map)
    Module.register_attribute(caller, :count_map, accumulate: false)
    Module.put_attribute(caller, :count_map, count_map)
    Module.register_attribute(caller, :hash_parts, accumulate: false)
    Module.put_attribute(caller, :hash_parts, hash_parts)
    Module.register_attribute(caller, :block_size, accumulate: false)
    Module.put_attribute(caller, :block_size, block_size)

  	quote do
  	  alias __MODULE__
  	  IO.inspect(__MODULE__)

      Kernel.defstruct @enforce_keys ++ [:name]

	  @doc """
	  Generates a random #{__MODULE__} without a name, that cannot be
	  regenerated based on a given name.

	  Returns `%#{__MODULE__}{}`.

	  ## Examples

	      iex> #{__MODULE__}.random()
	      %#{__MODULE__}{}

	  """
      def random() do
	    Enum.reduce(@enforce_keys, %{}, fn field, acc -> 
	      Map.put(acc, field, Enum.random(File.ls!("#{@base_dir}/#{field}/")))
	    end)
	    |> (&struct(__MODULE__, &1)).()
	  end

	  # Generates a #{__MODULE__} without a name from a hashed_string.
	  # Partitions the hashed bitstring into blocks based on the number of 
	  # provided fields.

	  # Returns `%#{__MODULE__}{}`.
	  defp generate_hashed(hash) when byte_size(hash) == 64 do
	    @enforce_keys
	    |> Enum.zip(for <<block::@block_size <- hash >>, do: block)
	    |> Enum.map(fn {k, v} -> {k, rem(v, Map.get(@count_map, k))} end)
	    |> Enum.map(fn {k, v} -> {k, Enum.fetch!(Map.get(@file_map, k), v)} end)
	    |> Map.new()
	    |> (&struct(__MODULE__, &1)).()
	  end

	  @doc """
	  Generates a #{__MODULE__} with the provided name.

	  Returns `%#{__MODULE__}{name: name, ...}`.

	  ## Examples

	      iex> #{__MODULE__}.generate("my_#{String.downcase(List.last(Module.split(__MODULE__)))}")
	      %#{__MODULE__}{}

	  """
	  def generate(string) when is_binary(string) do
	  	hash(string)
	  	|> generate_hashed()
	  	|> Map.put(:name, string)
	  end

	  @doc """
	  Renders an image for a provided #{__MODULE__}  in the output directory.

	  Returns `VipsImage`.

	  ## Examples

	      iex> #{__MODULE__}.render("my_#{String.downcase(List.last(Module.split(__MODULE__)))}")
	      %#{__MODULE__}{}

	  """
	  def render(%__MODULE__{} = module_struct) do
	  	module_name = String.downcase(List.last(Module.split(__MODULE__)))
	  	name = case module_struct.name do
	  		nil -> :rand.uniform(24)
	  		name -> name
	  	end
	    @enforce_keys
	    |> Enum.map(&Image.open!("#{@base_dir}/#{&1}/#{Map.get(module_struct, &1)}"))
	    |> Enum.reduce(fn image, composite -> 
	      Image.compose!(composite, image)
	    end)
	    |> Image.write!("#{@output_dir}/#{name}-#{module_name}.png")
	  end

	  @doc """
	  Generates a #{__MODULE__} with the specified name.
	  Renders an image in the output directory.

	  Returns `VipsImage`.

	  ## Examples

	      iex> #{__MODULE__}.render("my_#{String.downcase(List.last(Module.split(__MODULE__)))}")
	      %#{__MODULE__}{}

	  """
	  def render(name) when is_binary(name) do
	  	generate(name)
	  	|> render()
	  end

	  defp hash(avatar_string) when is_binary(avatar_string) do
	    :crypto.hash(:sha512, avatar_string) 
	  end

	  defoverridable render: 1, hash: 1
    end
  end
end