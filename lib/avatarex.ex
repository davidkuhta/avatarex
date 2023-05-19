defmodule Avatarex do
  @moduledoc """
  Avatarex is is an elixir package for generating unique, reproducible avatars.

  The package is inspired by [Robohash](https://github.com/e1ven/Robohash)

  Two Avatar sets are natively `Avatarex.Sets.Birdy` and `Avatarex.Sets.Kitty`, but
  additional sets can be created using `Avatarex.Set`.

  Optional parameter:
  
    renders_path: The absolute path to the directory in which to render images.
    Will default to "avatarex/priv/renders" if unset or path doesn't exist.

  ## Example Usage
      defmodule MyApp.Avatar do
        use Avatarex, renders_path: :my_app |> :code.priv_dir() |> Path.join("renders")

        alias Avatarex.Sets.{Birdy, Kitty}

        for {name, module} <- [birdy: Birdy, kitty: Kitty] do
          set name, module
        end
      end
  """
  @moduledoc since: "0.1.0"

  require Logger

  @spec __before_compile__(any) :: Macro.t
  # credo:disable-for-next-line
  defmacro __before_compile__(_env) do
    quote unquote: false do

      set_list = "#{inspect Keyword.keys(@sets)}"

      @doc """
      Generates a reproducible #{__MODULE__} for a given name and set 
      in #{set_list}.

      Returns `%#{__MODULE__}{image: nil, name: ...}`.

      ## Examples

          iex> #{__MODULE__}.generate("user_name", :kitty)
          %#{__MODULE__}{image: nil, name: "bob", set: kitty, renders_path: ...}

      """
      @spec generate(set :: String.t, module :: atom) :: Avatarex.t_nil_image
      for {set, module} <- @sets do
        def generate(name, unquote(set)) do
          Avatarex.generate(name, unquote(module), unquote(set), @renders_path)
        end
      end


      @doc """
      Generates an unreproducible random #{__MODULE__} from a set in #{set_list}.

      Returns `%#{__MODULE__}{image: nil, name: ...}`.

      ## Examples

          iex> #{__MODULE__}.random()
          %#{__MODULE__}{image: nil, name: nil, set: birdy, renders_path: ...}

      """
      @spec random() :: Avatarex.t_nil_image
      def random do
        {set, module} = Enum.random(@sets)
        Avatarex.random(module, set, @renders_path)
      end

      @doc """
      Generates an unreproducible random #{__MODULE__} for a given set in #{set_list}.

      Returns `%#{__MODULE__}{image: nil, name: ...}`.

      ## Examples

          iex> #{__MODULE__}.random(:kitty)
          %#{__MODULE__}{image: nil, name: nil, set: kitty, renders_path: ...}

      """
      @spec random(set :: atom) :: Avatarex.t_nil_image
      for {set, module} <- @sets do
        def random(unquote(set)) do
          Avatarex.random(unquote(module), unquote(set), @renders_path)
        end
      end

      @doc """
      Generates a random #{__MODULE__} for a set in #{set_list}
      and renders a composite image.

      Returns `%#{__MODULE__}{image: %Vix.Vips.Image{}, set: ...}`.

      ## Examples

          iex> #{__MODULE__}.generate(:kitty)
          %#{__MODULE__}{image: %Vix.Vips.Image{}, name: 5, set: :kitty...}

      """
      @spec render(set :: atom) :: Avatarex.t
      for {set, module} <- @sets do
        def render(unquote(set)) do
          Avatarex.render(unquote(module), unquote(set), @renders_path)
        end
      end

      @doc """
      Renders a #{__MODULE__} to form a composite image.

      Returns `%#{__MODULE__}{image:  %Vix.Vips.Image{}, ...}`.

      ## Examples

          iex> #{__MODULE__}.render(%#{__MODULE__}{})
          %#{__MODULE__}{image: %Vix.Vips.Image{}, ...}

      """
      @spec render(avatar :: Avatarex.t) :: Avatarex.t
      def render(avatar) do
        Avatarex.render(avatar)
      end

      @doc """
      Generates a #{__MODULE__} for a given name and set in #{set_list}
      and renders a composite image

      Returns `%#{__MODULE__}{image:  %Vix.Vips.Image{}, name: ...}`.

      ## Examples

          iex> #{__MODULE__}.write("user_name, :kitty)
          %#{__MODULE__}{image: %Vix.Vips.Image{}, name: "user_name", set: :kitty...}

      """
      @spec render(name :: String.t, set :: atom) :: Avatarex.t
      for {set, module} <- @sets do
        def render(name, unquote(set)) do
          Avatarex.render(name, unquote(module), unquote(set), @renders_path)
        end
      end

      @doc """
      Writes a #{__MODULE__} to initialized renders path.

      Returns `%#{__MODULE__}{image:  %Vix.Vips.Image{}, name: ...}`.

      ## Examples

          iex> #{__MODULE__}.write(%#{__MODULE__}{})
          %#{__MODULE__}{image: %Vix.Vips.Image{}, name: "user_name", set: :kitty...}

      """
      @spec write(avatar :: Avatarex.t) :: Avatarex.t
      def write(avatar) do
        Avatarex.write(avatar)
      end
    end
  end


  @spec __using__([opts: String.t]) :: Macro.t
  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      @before_compile Avatarex
      # @renders_path opts[:renders_path] || :avatarex |> :code.priv_dir() |> Path.join("renders")

      default_path = :avatarex |> :code.priv_dir() |> Path.join("renders")
      @renders_path (case opts[:renders_path] do
        nil -> default_path
        path -> if File.exists?(path), do: path, else: default_path
      end)

      unless File.exists?(@renders_path), do: File.mkdir_p(@renders_path)

      Module.register_attribute(__MODULE__, :sets, accumulate: true)
      import Avatarex, only: [set: 2]
    end
  end

  @doc """
  Macro that adds the provided {set, module} to the available #{__MODULE__} sets.

  ## Examples

      use Avatarex, renders_path:...

      set {:kitty, Avatarex.Sets.Kitty}

  """
  @spec set(atom, atom) :: Macro.t
  defmacro set(set, module) do
    quote bind_quoted: [module: module, set: set] do
      @sets {set, module}
    end
  end

  defstruct [:image, :name, :set, :renders_path, images: []]
  # @type t(first, last) :: %__MODULE__{first: first, last: last}

  @type t :: %__MODULE__{image: Vix.Vips.Image.t, name: String.t | pos_integer(), 
                         set: atom, renders_path: String.t, images: [{String.t, String.t}]}
  @type t_nil_image :: %__MODULE__{image: nil, name: String.t | pos_integer(), set: atom, 
                              renders_path: String.t, images: [{String.t, String.t}]}

  @doc """
  Writes a #{__MODULE__} to render path.

  Returns `%#{__MODULE__}{image:  %Vix.Vips.Image{}, name: ...}`.

  ## Examples

      iex> #{__MODULE__}.generate(%#{__MODULE__}{})
      %#{__MODULE__}{image: %Vix.Vips.Image{}, name: "user_name", set: :kitty...}

  """
  @spec generate(name :: String.t, module :: atom, set :: atom, renders_path :: String.t) :: Avatarex.t_nil_image
  def generate(name, module, set, renders_path)
      when is_atom(module) and is_binary(name) and is_atom(set) and is_binary(renders_path) do
    hash = :crypto.hash(:sha512, name)
    keys = module.get_keys()
    hash_parts = div(128, Enum.count(keys) + 1)
    block_size = div(512, hash_parts)

    keys
    |> Enum.zip(for <<block::size(block_size) <- hash>>, do: block)
    |> Enum.map(fn {key, value} ->
      index = rem(value, module.get_image_count(key))
      {key, module.get_image_path_by_index(key, index)}
    end)
    |> construct(set, name, renders_path)
  end

  @doc """
  Generates a #{__MODULE__} to render path for a given #{__MODULE__}.Set

  Returns `%#{__MODULE__}{image: %Vix.Vips.Image{}, name: ...}`.

  ## Examples
      iex> alias Avatarex.Sets.Kitty
      iex> #{__MODULE__}.random(Kitty, :kitty, "priv/render")
      %#{__MODULE__}{image: %Vix.Vips.Image{}, name: "user_name", set: :kitty...}

  """
  @spec random(module :: atom, set :: atom, renders_path :: String.t) :: Avatarex.t_nil_image
  def random(module, set, renders_path)
      when is_atom(module) and is_atom(set) and is_binary(renders_path) do
    module.get_keys()
    |> Enum.reduce([], fn key, acc ->
      module.get_images_paths(key)
      |> Enum.random()
      |> then(&[{key, &1} | acc])
    end)
    |> construct(set, :rand.uniform(24), renders_path)
  end

  @spec construct(images :: [{}], set :: atom, name :: String.t | pos_integer, renders_path :: String.t) :: Avatarex.t_nil_image
  defp construct(images, set, name, renders_path) do
    %__MODULE__{images: images, set: set, name: name, renders_path: renders_path}
    |> log(:generate)
  end

  @doc """
  Renders a #{__MODULE__} with a composite image.

  Returns `%#{__MODULE__}{image: ...}`.

  ## Examples

      iex> #{__MODULE__}.render(%#{__MODULE__}{images: images})
      %#{__MODULE__}{image: %Vix.Vips.Image{}, name: "user_name", set: :kitty...}

  """
  @spec render(avatar :: Avatarex.t | Avatarex.t_nil_image) :: Avatarex.t
  def render(%__MODULE__{images: images} = avatar) do
    images
    |> Keyword.values()
    |> Enum.reduce(nil, fn
      image, nil -> Image.open!(image)
      image, composite -> Image.compose!(composite, Image.open!(image))
    end)
    |> then(&%__MODULE__{avatar | image: &1})
    |> log(:render)
  end

  @doc """
  Generates an unreproducible random #{__MODULE__} for a set and render path
  and renders the composite image.

  Returns `%#{__MODULE__}{image: ...}`.

  ## Examples

      iex> #{__MODULE__}.render(%#{__MODULE__}{images: images})
      %#{__MODULE__}{image: %Vix.Vips.Image{}, name: "user_name", set: :kitty...}

  """
  @spec render(module :: atom, set :: atom, renders_path :: String.t) :: Avatarex.t
  def render(module, set, renders_path)
      when is_atom(module) and is_atom(set) and is_binary(renders_path) do
    module |> random(set, renders_path) |> render()
  end

  @doc """
  Generates a reproducible random #{__MODULE__} for a given name and set and 
  renders the composite image.

  Returns `%#{__MODULE__}{image: ...}`.

  ## Examples

      iex> alias Avatarex.Sets.Kitty
      iex> #{__MODULE__}.render("user_name", Kitty, :kitty, "/renders/...")
      %#{__MODULE__}{image: %Vix.Vips.Image{}, name: "user_name", set: :kitty...}

  """
  @spec render(name :: String.t, module :: atom, set :: atom, renders_path :: String.t) :: Avatarex.t
  def render(name, module, set, renders_path)
      when is_atom(module) and is_atom(set) and is_binary(name) and is_binary(renders_path) do
    name |> generate(module, set, renders_path) |> render()
  end

  @doc """
  Renders a #{__MODULE__} composite image and writes the image.

  Returns `%#{__MODULE__}{image: %Vix.Vips.Image{}}`.

  ## Examples

      iex> alias Avatarex.Sets.Kitty
      iex> #{__MODULE__}.render("user_name", Kitty, :kitty, "/renders/...")
      %#{__MODULE__}{image: %Vix.Vips.Image{}, name: "user_name", set: :kitty...}

  """
  @spec write(avatar :: Avatarex.t_nil_image) :: Avatarex.t
  def write(%__MODULE__{image: nil} = avatar) do
    avatar |> render() |> write()
  end

  @spec write(avatar :: Avatarex.t) :: Avatarex.t
  def write(%__MODULE__{image: image, set: set, name: name, renders_path: renders_path} = avatar) do
    renders_path
    |> Path.join("#{name}_#{set}.png")
    |> then(&Image.write!(image, &1))
    |> then(&%{avatar | image: &1})
    |> log(:write)
  end

  @doc """
  Returns a full path to the directory for a given set. If a module is provided,
  an expected path is returned using the downcased string of the modules default
  alias.

  ## Examples

      iex> set_dir("kitty")
      iex> ".../my_app/priv/sets/kitty")

      iex> alias MyApp.Avatar.Set.Robot
      iex> set_dir(Robot)
      iex> ".../my_app/priv/sets/robot")

  """
  @spec set_dir(set :: String.t) :: set_dir :: String.t
  def set_dir(set) when is_binary(set) do
    :avatarex |> :code.priv_dir() |> then(&[&1, "sets", set]) |> Path.join()
  end

  @spec set_dir(module :: atom) :: set_dir :: String.t
  def set_dir(module) when is_atom(module) do
    module
    |> to_string()
    |> String.split(".")
    |> List.last 
    |> String.downcase() 
    |> set_dir()
  end

  @spec log(avatar :: Avatarex.t | Avatarex.t_nil_image, action :: atom) :: Avatarex.t | Avatarex.t_nil_image
  defp log(avatar, action) do
    case action do
      :generate -> "Generate a #{avatar.set} avatar"
      :render -> "Rendering #{avatar.set} avatar named #{avatar.name}"
      :write -> "Writing image '#{avatar.name}_#{avatar.set}.png' to renders path"
    end
    |> Logger.info()
    avatar
  end
end
