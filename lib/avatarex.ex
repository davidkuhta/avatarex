defmodule Avatarex do
  @moduledoc """
  Avatarex is is an elixir package for generating unique, reproducible avatars.

  The package is inspired by [Robohash](https://github.com/e1ven/Robohash)

  Two Avatar sets are natively `Avatarex.Sets.Birdy` and `Avatarex.Sets.Kitty`, but
  additional sets can be created using `Avatarex.Set`.

  Optional parameters:

    otp_app: The parent application to be used to generate the sets path.

    sets_path: The fully qualified sets path or path relative to the otp application's priv directory.
    Will default to "myapp/priv/sets" if unset.

    renders_path: The absolute path to the directory in which to render images.
    Will default to "myapp/priv/renders" if unset or path doesn't exist.

  Logs avatar generation, rendering, and writing of rendered avatar.

  ## Example Usage
      defmodule MyApp.Avatar do
        use Avatarex

        alias Avatarex.Sets.{Birdy, Kitty}

        for {name, module} <- [birdy: Birdy, kitty: Kitty] do
          set name, module
        end
      end
  """

  require Logger

  @spec __before_compile__(env :: Macro.Env.t()) :: Macro.t
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
          %#{__MODULE__}{image: nil, name: "bob", set: :kitty, renders_path: ...}

      """
      @spec generate(Avatarex.set, Avatarex.set_module) :: Avatarex.t_unrendered
      for {set, module} <- @sets do
        def generate(name, unquote(set)) do
          Avatarex.generate(name, unquote(module), unquote(set), @renders_path)
        end
      end

      @doc """
      Generates an unreproducible random #{__MODULE__} from a set in #{set_list}.

      Returns `%#{__MODULE__}{image: nil, name: ...}`.

      ## Examples

          #{__MODULE__}.random()
          %#{__MODULE__}{image: nil, name: nil, set: :birdy, renders_path: ...}

      """
      @spec random() :: Avatarex.t_unrendered
      def random do
        {set, module} = Enum.random(@sets)
        Avatarex.random(module, set, @renders_path)
      end

      @doc """
      Generates an unreproducible random #{__MODULE__} for a given set in #{set_list}.

      Returns `%#{__MODULE__}{image: nil, name: ...}`.

      ## Examples

          #{__MODULE__}.random(:kitty)
          %#{__MODULE__}{image: nil, name: nil, set: :kitty, renders_path: ...}

      """
      @spec random(Avatarex.set) :: Avatarex.t_unrendered
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

          #{__MODULE__}.generate(:kitty)
          %#{__MODULE__}{image: %Vix.Vips.Image{}, name: 5, set: :kitty...}

      """
      @spec render(Avatarex.set) :: Avatarex.t
      for {set, module} <- @sets do
        def render(unquote(set)) do
          Avatarex.render(unquote(module), unquote(set), @renders_path)
        end
      end

      @doc """
      Renders a #{__MODULE__} to form a composite image.

      Returns `%#{__MODULE__}{image:  %Vix.Vips.Image{}, ...}`.

      ## Examples

          #{__MODULE__}.render(%#{__MODULE__}{})
          %#{__MODULE__}{image: %Vix.Vips.Image{}, ...}

      """
      @spec render(Avatarex.t) :: Avatarex.t
      def render(avatar) do
        Avatarex.render(avatar)
      end

      @doc """
      Generates a #{__MODULE__} for a given name and set in #{set_list}
      and renders a composite image

      Returns `%#{__MODULE__}{image:  %Vix.Vips.Image{}, name: ...}`.

      ## Examples

          #{__MODULE__}.write("user_name, :kitty)
          %#{__MODULE__}{image: %Vix.Vips.Image{}, name: "user_name", set: :kitty...}

      """
      @spec render(Avatarex.name, Avatarex.set) :: Avatarex.t
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
      @spec write(Avatarex.t) :: Avatarex.t
      def write(avatar) do
        Avatarex.write(avatar)
      end
    end
  end

  @spec __using__([opts: String.t]) :: Macro.t
  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      @before_compile Avatarex

      @app (case opts[:otp_app] do
        nil -> :avatarex
        app -> app
      end)

      @sets_path (case opts[:sets_path] do
        nil -> "sets"
        path -> path
      end)

      @sets_dir (if File.exists?(@sets_path) do
          @sets_path
        else
          @app |> :code.priv_dir |> Path.join(@sets_path)
        end)

      unless File.exists?(@sets_dir), do: File.mkdir_p(@sets_dir)
      IO.inspect(@sets_dir)

      @doc """
      Returns a full path to the default directory for this avatar's sets.

      ## Examples

          sets_dir("kitty")
          "../my_app/priv/sets/")

          alias MyApp.Avatar.Set.Robot
          sets_dir(Robot)
          ".../my_app/priv/sets/")

      """
      @spec sets_dir() :: sets_dir :: String.t
      def sets_dir(), do: @sets_dir

      @renders_path (case opts[:renders_path] do
        nil -> "renders"
        path -> path
      end)

      @renders_path (if File.exists?(@renders_path) do
        @renders_path
      else
        @app |> :code.priv_dir |> Path.join(@renders_path)
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
  @spec set(Avatarex.set, Avatarex.set_module) :: Macro.t
  defmacro set(set, module) do
    quote bind_quoted: [module: module, set: set] do
      @sets {set, module}
    end
  end

  defstruct [:image, :name, :set, :renders_path, images: []]

  @typedoc "This type"
  @type t(image) :: %__MODULE__{image: image, name: String.t | pos_integer(), 
                         set: atom, renders_path: String.t, images: [{Avatarex.Set.layer, Avatarex.Set.image_path}]}
  
  @typedoc "An Avatarex type"
  @type t :: t(Vix.Vips.Image.t | nil)

  @typedoc "An unrendered Avatarex type"
  @type t_unrendered :: t(nil)

  @typedoc "A rendered Avatarex type"
  @type t_rendered :: t(Vix.Vips.Image.t)

  @typedoc "A render path"
  @type renders_path :: String.t

  @typedoc "A name used for avatar and subsequent rendered file name"
  @type name :: String.t | pos_integer

  @typedoc "An Avatarex set atom"
  @type set :: atom

  @typedoc "A module which conforms to Avatar Set behaviour"
  @type set_module :: module

  @typedoc "A list of Avatarex Set layer and Avatarex Set image _path tuples"
  @type images :: [{Avatarex.Set.layer, Avatarex.Set.image_path}]

  @typep log_action :: :generate | :render | :write

  @doc """
  Writes a #{__MODULE__} to render path.

  Returns `%#{__MODULE__}{image:  %Vix.Vips.Image{}, name: ...}`.

  ## Examples

      # iex> alias #{__MODULE__}.Sets.Kitty
      # iex> default_path = :avatarex |> :code.priv_dir() |> Path.join("renders")
      # iex> #{__MODULE__}.generate("david", Kitty, :kitty, default_path)
      # %#{__MODULE__}{image: nil, name: "david", set: :kitty, renders_path: default_path,
      #               images: [
      #                 {"body", Path.join(Kitty.get_path(), "/body/body_7.png")},
      #                 {"eye", Path.join(Kitty.get_path(), "/eye/eye_7.png")},
      #                 {"fur", Path.join(Kitty.get_path(), "/fur/fur_1.png")},
      #                 {"mouth", Path.join(Kitty.get_path(), "/mouth/mouth_6.png")},
      #                 {"accessorie", Path.join(Kitty.get_path(), "/accessorie/accessorie_20.png")}
      #               ]}

  """
  @spec generate(Avatarex.name, Avatarex.set_module, Avatarex.set, Avatarex.renders_path) :: Avatarex.t_unrendered
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
      alias Avatarex.Sets.Kitty
      #{__MODULE__}.random(Kitty, :kitty, "priv/render")
      %#{__MODULE__}{image: %Vix.Vips.Image{}, name: "user_name", set: :kitty...}

  """
  @spec random(Avatarex.set_module, Avatarex.set, Avatarex.renders_path) :: Avatarex.t_unrendered
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

  @spec construct(Avatarex.images, Avatarex.set, Avatarex.name, Avatarex.renders_path) :: Avatarex.t_unrendered
  defp construct(images, set, name, renders_path) do
    %__MODULE__{images: images, set: set, name: name, renders_path: renders_path}
    |> log(:generate)
  end

  @doc """
  Renders a #{__MODULE__} with a composite image.

  Returns `%#{__MODULE__}{image: ...}`.

  ## Examples
      
      #{__MODULE__}.render(%#{__MODULE__}{images: _})
      %#{__MODULE__}{image: %Vix.Vips.Image{}, name: "user_name", set: :kitty...}

  """
  @spec render(Avatarex.t) :: Avatarex.t_rendered
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

      #{__MODULE__}.render(%#{__MODULE__}{images: _})
      %#{__MODULE__}{image: %Vix.Vips.Image{}, name: "user_name", set: :kitty...}

  """
  @spec render(Avatarex.set_module, Avatarex.set, Avatarex.renders_path) :: Avatarex.t_rendered
  def render(module, set, renders_path)
      when is_atom(module) and is_atom(set) and is_binary(renders_path) do
    module |> random(set, renders_path) |> render()
  end

  @doc """
  Generates a reproducible random #{__MODULE__} for a given name and set and 
  renders the composite image.

  Returns `%#{__MODULE__}{image: ...}`.

  ## Examples

      #{__MODULE__}.render("user_name", Avatarex.Sets.Kitty, :kitty, "/renders/...")
      %#{__MODULE__}{image: %Vix.Vips.Image{}, name: "user_name", set: :kitty...}

  """
  @spec render(Avatarex.name, Avatarex.set_module, Avatarex.set, Avatarex.renders_path) :: Avatarex.t_rendered
  def render(name, module, set, renders_path)
      when is_atom(module) and is_atom(set) and is_binary(name) and is_binary(renders_path) do
    name |> generate(module, set, renders_path) |> render()
  end

  @doc """
  Renders a #{__MODULE__} composite image and writes the image at the designated
  renders path with the form "{name}_{set}.png". Spaces in {name} are replaced with
  underscores.

  Returns `%#{__MODULE__}{image: %Vix.Vips.Image{}}`.

  ## Examples

      #{__MODULE__}.render("user_name", Avatarex.Sets.Kitty, :kitty, "/renders/...")
      %#{__MODULE__}{image: %Vix.Vips.Image{}, name: "user_name", set: :kitty...}

  """
  @spec write(avatar :: Avatarex.t_unrendered) :: Avatarex.t_rendered
  def write(%__MODULE__{image: nil} = avatar) do
    avatar |> render() |> write()
  end

  @spec write(avatar :: Avatarex.t_rendered) :: Avatarex.t_rendered
  def write(%__MODULE__{image: image, set: set, name: name, renders_path: renders_path} = avatar) do
    "#{name}_#{set}.png"
    |> String.replace(" ", "_")
    |> then(&Path.join(renders_path, &1))
    |> then(&Image.write!(image, &1))
    |> then(&%{avatar | image: &1})
    |> log(:write)
  end

  @spec log(Avatarex.t, action :: Avatarex.log_action) :: Avatarex.t
  defp log(avatar, action) do
    case action do
      :generate -> "Generating a #{avatar.set} avatar"
      :render -> "Rendering #{avatar.set} avatar named #{avatar.name}"
      :write -> "Writing image '#{avatar.name}_#{avatar.set}.png' to renders path"
    end
    |> Logger.info()
    avatar
  end
end
