defmodule Avatarex.Set do
  @moduledoc """
  This module provides functions for creating an `AvatarexSet`
  """

  @doc """
  Generates all functions for generating `AvatarexSet`s and associated renders

  Required opts:
  	set_dir: "/path/to/my_set/"
  	keys: [:field1, :field2, :field3]

  `set_dir` path to set directory: `"/path/to/my_set/"`

  `keys` correspond to folders under the `set_dir`, ex: `"/path/to/my_set/field1"`
  `keys` ordering will correspond to image layering. `[:base_layer, :next_layer, ...]`

  Optional opts:
    otp_app: :my_app
    ren_dir: "/path/to/render/"

  By default, Avatarex.Set expects renders to be stored under the `priv/renders`
  directory of an application. This behaviour can be changed by specifying a
  `ren_dir:` option when using `Avatarex.Set`:

      # Look for renders in my_app/priv/images instead of
      # my_app/priv/renders
      use Avatarex.Set, otp_app: :my_app, ren_dir: "images"

  Both `set_dir` and `ren_dir` accept both path strings and word lists. 
  Paths are expected to be relative to `/priv`.

  ## Examples
      iex> use #{__MODULE__}, dir: "/path/to/my_set", keys: [:field1, :field2, :field3] 

  """
  @moduledoc since: "0.1.0"

  require Logger

  defmacro __using__(opts) do
    caller = __CALLER__.module

    otp_app = Keyword.get(opts, :otp_app, nil)

    Logger.info("Otp App: #{otp_app} , for #{caller}")

  	priv_dir = case otp_app do
  		nil -> :avatarex |> :code.priv_dir()
  		otp_app -> otp_app |> :code.priv_dir()
    end

		set_dir = case Keyword.get(opts, :set_dir) do
			nil -> raise ArgumentError, ":set_dir option required \n 'path/to/set', ~w[path to set]"
			{:sigil_w, _, [{_,_,[dir]}, _]} -> Path.join(priv_dir, Path.join(String.split(dir)))
			dir -> Path.join(priv_dir, dir)
		end
    Logger.info("#{caller } Set Directory #{set_dir}")

		if !File.exists?(set_dir) do
			raise File.Error, "Set Directory does not exist"
		end

  	dir_fields = case File.ls(set_dir) do
  		{:error, _} -> raise "Directory ls error"
  		{:ok, files} -> files
  	end

  	keys = case Keyword.get(opts, :keys) do
  		nil -> raise ArgumentError, ":keys option required \n [:field1, :field2, ...], ~w[field1 field2]a"
  		{:sigil_w, _, [{_,_,[keys]}, 'a']} ->
  			Enum.map(String.split(keys), &String.to_atom(&1))
  		keys -> keys
  	end

  	for field <- keys do
  		if !Enum.member?(dir_fields, to_string(field)), 
  			do: raise ArgumentError, "#{field}/ folder not found in #{set_dir}"
  	end

  	ren_dir = case Keyword.get(opts, :ren_dir) do
  		nil -> Path.join(priv_dir, "renders")
  		{:sigil_w, _, [{_,_,[dir]}, _]} -> Path.join(priv_dir, Path.join(String.split(dir)))
  		dir -> Path.join(priv_dir, dir)
  	end
    Logger.info("#{caller} Render Directory: #{ren_dir}")

  	if !File.exists?(ren_dir) do
			File.mkdir_p!(ren_dir)
			Logger.info("Created render directory")
		end

		file_map = Map.new(keys, fn k -> {k, File.ls!("#{set_dir}/#{k}/")} end)
		count_map = Map.new(file_map, fn {k, v} -> {k, Enum.count(v)} end)
		hash_parts = div(128, Enum.count(keys) + 1)
		block_size = div(512, hash_parts)

    # Define the attribute and set it in the calling module
    Module.register_attribute(caller, :otp_app, accumulate: false)
    Module.put_attribute(caller, :otp_app, otp_app)
    Module.register_attribute(caller, :set_dir, accumulate: false)
    Module.put_attribute(caller, :set_dir, set_dir)
    Module.register_attribute(caller, :enforce_keys, accumulate: false)
    Module.put_attribute(caller, :enforce_keys, keys)
    Module.register_attribute(caller, :ren_dir, accumulate: false)
    Module.put_attribute(caller, :ren_dir, ren_dir)
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
		      Map.put(acc, field, Enum.random(File.ls!("#{@set_dir}/#{field}/")))
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
		    @enforce_keys
		    |> Enum.map(&[@set_dir, Atom.to_string(&1), Map.get(module_struct, &1)])
		    |> Enum.map(&Path.join(&1))
		    |> Enum.map(&Image.open!(&1))
		    |> Enum.reduce(fn image, composite -> 
		      Image.compose!(composite, image)
		    end)
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

	  	@doc """
		  Writes an image for a provided %Vix.Vips.Image{} with a given name
		  in the output directory.

		  Returns `VipsImage`.

		  ## Examples

		      iex> #{__MODULE__}.write(%Vix.Vips.Image{}, "my_#{String.downcase(List.last(Module.split(__MODULE__)))}")
		      %#{__MODULE__}{}

		  """
		  def write(%Vix.Vips.Image{} = image, name) when is_binary(name) do
		  	module_name = String.downcase(List.last(Module.split(__MODULE__)))
		  	path = Path.join(@ren_dir, "#{name}-#{module_name}.png")

		  	image
		    |> Image.write!(path)
		  end

	  	@doc """
		  Writes an image for a provided #{__MODULE__} to the output directory.

		  Returns `VipsImage`.

		  ## Examples

		      iex> #{__MODULE__}.write("%#{__MODULE__}{}")
		      %#{__MODULE__}{}

		  """
		  def write(%__MODULE__{} = module_struct) do
		  	name = case module_struct.name do
		  		nil -> :rand.uniform(24)
		  		name -> name
		  	end

		  	render(module_struct)
		  	|> write(name)
		  end

	  	@doc """
		  Writes an image for a provided #{__MODULE__} to the output directory.

		  Returns `VipsImage`.

		  ## Examples

		      iex> #{__MODULE__}.write("my_#{String.downcase(List.last(Module.split(__MODULE__)))}")
		      %#{__MODULE__}{}

		  """
		  def write(name) when is_binary(name) do
		  	generate(name)
		  	|> write()
		  end

		  defp hash(avatar_string) when is_binary(avatar_string) do
		    :crypto.hash(:sha512, avatar_string) 
		  end

	  	defoverridable render: 1, hash: 1
    end
  end
end