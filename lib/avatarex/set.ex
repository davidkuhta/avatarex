defmodule Avatarex.Set do
  @moduledoc """
  This module provides functions for generating an `Avatarex.Set`

  Optional parameters:

    avatar: A reference to an Avatarex Avatar used for generating a set path.

    path: The fully qualified path in which to find the layers for the set. If no path has
    been provided, an an avatar is passed, uses the avatar's sets_path and downcased string
    of the module's default alias.

    layer_order: A word list of the features corresponding to the folders for the set.
    Order corresponds to the rendering order [base -> final]. Defaults to the `ls` for the
    path option if not provided.

  ## Example Usage

      defmodule Avatarex.Sets.Birdy do
        use Avatarex.Set, layer_order: ~w[body hoop tail wing eyes bec accessorie]
      end

      defmodule MyApp.Avatar.Sets.Robot do
        use Avatarex.Set, layer_order: ["body" "head" "arms" "badge"]
      end

      defmodule MyApp.Avatar.Sets.BlueBots do
        use Avatarex.Set, path: "robot", layer_order: ["body" "head" "arms" "badge"]
      end

  """
  @typedoc "A path to an avatarex set"
  @type path :: String.t

  @typedoc "A path a particular avatarex set layer"
  @type layer :: String.t

  @typedoc "A path to a particular avatarex set layer"
  @type layer_path :: String.t

  @typedoc "A path to an individual image in an avatarex set layer"
  @type image_path :: String.t

  @doc """
  Returns keys for the set.
  """
  @callback get_keys() :: keys :: [Avatarex.Set.layer]

  @doc """
  Returns the path to the set.
  """
  @callback get_path() :: Avatarex.Set.path

  @doc """
  Returns the count of images for a given layer in the set.
  """
  @callback get_image_count(Avatarex.Set.layer) :: image_count :: integer

  @doc """
  Returns the path of images for a given layer in the set.
  """
  @callback get_images_paths(Avatarex.Set.layer) :: layer_images_path :: [Avatarex.Set.image_path]

  @doc """
  Returns the path for a particular image of a given layer in the set.
  """
  @callback get_image_path_by_index(Avatarex.Set.layer, index :: integer) :: layer_image_path_for_index :: Avatarex.Set.image_path


  @spec __using__([opts: String.t]) :: Macro.t
  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do

      @behaviour Avatarex.Set

      @avatar_module opts[:avatar]

      sets_dir = case @avatar_module do
        nil -> :avatarex |> :code.priv_dir() |> Path.join("sets")
        app -> @avatar_module.sets_dir()
      end

      @path (case opts[:path] do
        nil -> 
          __MODULE__
          |> to_string()
          |> String.split(".")
          |> List.last 
          |> String.downcase()
          |> then(&Path.join(sets_dir, &1))
        path -> if File.exists?(path) do
            path
          else
            Path.join(sets_dir, path)
          end
      end)
      
      @keys (case opts[:layer_order] do
        nil -> File.ls!(@path) |> Enum.sort()
        keys -> keys
      end)

      @doc """
      Returns keys for the set.
      """
      @spec get_keys() :: keys :: [Avatarex.Set.layer]
      def get_keys, do: @keys

      @doc """
      Returns the path to the set.
      """
      @spec get_path() :: Avatarex.Set.path
      def get_path, do: @path

      @doc """
      Returns the count of images for a given layer in the set.
      """
      @spec get_image_count(Avatarex.Set.layer) :: image_count :: integer
      for layer <- @keys,
          count = @path |> Path.join(layer) |> File.ls!() |> Enum.count() do
        def get_image_count(unquote(layer)), do: unquote(count)
      end

      @doc """
      Returns the path of images for a given layer in the set.
      """
      @spec get_images_paths(Avatarex.Set.layer) :: layer_images_path :: [Avatarex.Set.image_path]
      for layer <- @keys,
          layer_path = Path.join(@path, layer),
          images = File.ls!(layer_path),
          images_paths = Enum.map(images, &Path.join(layer_path, &1)) do
        def get_images_paths(unquote(layer)), do: unquote(images_paths)
      end

      @doc """
      Returns the path for a particular image of a given layer in the set.
      """
      @spec get_image_path_by_index(Avatarex.Set.layer, index :: integer) :: layer_image_path_for_index :: Avatarex.Set.image_path
      for layer <- @keys,
          layer_path = Path.join(@path, layer),
          images = File.ls!(layer_path) |> Enum.sort() do

        for {image, index} <- images |> Enum.with_index(),
            path = Path.join(layer_path, image) do

          def get_image_path_by_index(unquote(layer), unquote(index)), do: unquote(path)
        end
      end
    end
  end
end
