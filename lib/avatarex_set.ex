defmodule AvatarexSet do
  # defmacro __using__(_opts) do
  #   import AvatarexSet
  # end

  defmacro directory_keys(dir, keys) do
    caller = __CALLER__.module

	file_map = Map.new(keys, fn k -> {k, File.ls!("#{dir}/#{k}/")} end)
	count_map = Map.new(file_map, fn {k, v} -> {k, Enum.count(v)} end)
	hash_parts = div(128, Enum.count(keys) + 1)
	block_size = div(512, hash_parts)
    # Define the attribute and set it in the calling module
    Module.register_attribute(caller, :base_dir, accumulate: false)
    Module.put_attribute(caller, :base_dir, dir)
    Module.register_attribute(caller, :enforce_keys, accumulate: false)
    Module.put_attribute(caller, :enforce_keys, keys)
    Module.register_attribute(caller, :file_map, accumulate: false)
    Module.put_attribute(caller, :file_map, file_map)
    Module.register_attribute(caller, :count_map, accumulate: false)
    Module.put_attribute(caller, :count_map, count_map)
    Module.register_attribute(caller, :hash_parts, accumulate: false)
    Module.put_attribute(caller, :hash_parts, hash_parts)
    Module.register_attribute(caller, :block_size, accumulate: false)
    Module.put_attribute(caller, :block_size, block_size)

  end

  defmacro base_dir(dir) do
    caller = __CALLER__.module

    # Define the attribute and set it in the calling module
    Module.register_attribute(caller, :base_dir, accumulate: false)
    Module.put_attribute(caller, :base_dir, dir)
  end

  defmacro enforce_keys(keys) do
    caller = __CALLER__.module

    # Define the attribute and set it in the calling module
    Module.register_attribute(caller, :enforce_keys, accumulate: false)
    Module.put_attribute(caller, :enforce_keys, keys)
  end

  defmacro base() do
    caller = __CALLER__.module
    IO.inspect(caller)
    # Code interpolated into the
    # calling site

    quote do
      Kernel.defstruct @enforce_keys

      def enforce_keys() do
        @enforce_keys
      end

      def random() do
	    Enum.reduce(@enforce_keys, %{}, fn field, acc -> 
	      Map.put(acc, field, Enum.random(File.ls!("#{@base_dir}/#{field}/")))
	    end)
	    |> (&struct(__MODULE__, &1)).()
	  end

	  def generate(hash) when is_bitstring(hash) do
	    @enforce_keys
	    |> Enum.zip(for <<block::@block_size <- hash >>, do: block)
	    |> Enum.map(fn {k, v} -> {k, rem(v, Map.get(@count_map, k))} end)
	    |> Enum.map(fn {k, v} -> {k, Enum.fetch!(Map.get(@file_map, k), v)} end)
	    |> Map.new()
	    |> (&struct(__MODULE__, &1)).()
	  end

	  def render(%__MODULE__{} = module_struct) do
	    @enforce_keys
	    |> Enum.map(&Image.open!("#{@base_dir}/#{&1}/#{Map.get(module_struct, &1)}"))
	    |> Enum.reduce(fn image, composite -> 
	      Image.compose!(composite, image)
	    end)
	    |> Image.write!("priv/renders/#{:rand.uniform(24)}.png")
	  end
    end
  end
end