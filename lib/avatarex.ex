defmodule Avatarex do
  defmacro __before_compile__(_env) do
    quote unquote: false do
      for {name, module} <- @sets do
        def generate(query, unquote(name)) do
          Avatarex.generate(query, unquote(module), unquote(name), @renders_path)
        end
      end

      for {name, module} <- @sets do
        def random(unquote(name)) do
          Avatarex.random(unquote(module), unquote(name), @renders_path)
        end
      end

      for {name, module} <- @sets do
        def render(unquote(name)) do
          Avatarex.render(unquote(module), unquote(name), @renders_path)
        end
      end

      for {name, module} <- @sets do
        def render(query, unquote(name)) do
          Avatarex.render(query, unquote(module), unquote(name), @renders_path)
        end
      end

      def random do
        {name, module} = Enum.random(@sets)
        Avatarex.random(module, name, @renders_path)
      end

      def render(set) do
        Avatarex.render(set)
      end

      def write(set) do
        Avatarex.write(set)
      end
    end
  end

  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      @before_compile Avatarex
      @renders_path opts[:renders_path] || raise("missing required option `:renders_path`")
      Module.register_attribute(__MODULE__, :sets, accumulate: true)
      import Avatarex, only: [set: 2]
    end
  end

  defmacro set(name, module) do
    quote bind_quoted: [module: module, name: name] do
      @sets {name, module}
    end
  end

  defstruct [:image, :name, :query, :renders_path, images: []]

  def generate(query, module, name, renders_path)
      when is_atom(module) and is_binary(query) and is_atom(name) and is_binary(renders_path) do
    hash = :crypto.hash(:sha512, query)
    keys = module.get_keys()
    hash_parts = div(128, Enum.count(keys) + 1)
    block_size = div(512, hash_parts)

    keys
    |> Enum.zip(for <<block::size(block_size) <- hash>>, do: block)
    |> Enum.map(fn {key, value} ->
      index = rem(value, module.get_image_count(key))
      {key, module.get_image_path_by_index(key, index)}
    end)
    |> construct(name, query, renders_path)
  end

  def random(module, name, renders_path)
      when is_atom(module) and is_atom(name) and is_binary(renders_path) do
    module.get_keys()
    |> Enum.reduce([], fn key, acc ->
      module.get_images_paths(key)
      |> Enum.random()
      |> then(&[{key, &1} | acc])
    end)
    |> construct(name, :rand.uniform(24), renders_path)
  end

  defp construct(images, name, query, renders_path) do
    %__MODULE__{images: images, name: name, query: query, renders_path: renders_path}
  end

  def render(%__MODULE__{images: images} = set) do
    images
    |> Keyword.values()
    |> Enum.reduce(nil, fn
      image, nil -> Image.open!(image)
      image, composite -> Image.compose!(composite, Image.open!(image))
    end)
    |> then(&%__MODULE__{set | image: &1})
  end

  def render(module, name, renders_path)
      when is_atom(module) and is_atom(name) and is_binary(renders_path) do
    module |> random(name, renders_path) |> render()
  end

  def render(query, module, name, renders_path)
      when is_atom(module) and is_atom(name) and is_binary(query) and is_binary(renders_path) do
    query |> generate(module, name, renders_path) |> render()
  end

  def write(%__MODULE__{image: nil} = set) do
    set |> render() |> write()
  end

  def write(%__MODULE__{image: image, name: name, query: query, renders_path: renders_path} = set) do
    renders_path
    |> Path.join("#{query}-#{name}.png")
    |> then(&Image.write!(image, &1))
    |> then(&%{set | image: &1})
  end

  def set_dir(name) do
    :avatarex |> :code.priv_dir() |> then(&[&1, "sets", name]) |> Path.join()
  end
end
