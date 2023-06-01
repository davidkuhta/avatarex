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
  alias __MODULE__

  @typedoc "A path to an avatarex set"
  @type path :: String.t

  @typedoc "A path a particular avatarex set layer"
  @type layer :: String.t

  @typedoc "A path to a particular avatarex set layer"
  @type layer_path :: String.t

  @typedoc "A path to an individual image in an avatarex set layer"
  @type image_path :: String.t

  @doc """
  Returns layers for the set.
  """
  @callback get_layers() :: layers :: [Set.layer]

  @doc """
  Returns the path to the set.
  """
  @callback get_path() :: Set.path

  @doc """
  Returns the count of images for a given layer in the set.
  """
  @callback get_image_count(Set.layer) :: image_count :: integer

  @doc """
  Returns the path of images for a given layer in the set.
  """
  @callback get_images_paths(Set.layer) :: layer_images_path :: [Set.image_path]

  @doc """
  Returns the path for a particular image of a given layer in the set.
  """
  @callback get_image_path_by_index(Set.layer, index :: integer) :: layer_image_path_for_index :: Set.image_path


  @spec __using__([opts: String.t]) :: Macro.t
  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do

      @behaviour Avatarex.Set

      @otp_app (case opts[:otp_app] do
        nil -> :avatarex
        app -> app
      end)
      IO.inspect(@otp_app)

      @sets_path (case opts[:avatar] do
        # nil -> @otp_app |> :code.priv_dir() |> Path.join("sets")
        nil -> "sets"
        avatar -> avatar.sets_path()
      end)
      IO.inspect(@sets_path)


      @path (case opts[:path] do
        nil -> 
          __MODULE__
          |> Macro.underscore()
          |> String.split("/")
          |> List.last
          |> then(&Path.join(@sets_path, &1))
        path -> if File.exists?(Path.join(@sets_path, path)) do
            IO.inspect("path exists")
            path
          else
            Path.join(@sets_path, path)
          end
      end)
      IO.inspect(@path)

      build_path = @otp_app |> :code.priv_dir() |> Path.join(@path)
      IO.inspect(build_path)
      
      @layers (case opts[:layer_order] do
        nil -> File.ls!(build_path) |> Enum.sort()
        layers -> layers
      end)

      def get_app, do: @otp_app

      def get_layers, do: @layers

      def get_path, do: @path

      for layer <- @layers,
        layer_path = Path.join(@path, layer),
        # images = File.ls!(layer_path) |> Enum.sort(),
        images = File.ls!(Path.join(build_path, layer)) |> Enum.sort(),
        count = Enum.count(images),
        images_paths = Enum.map(images, &Path.join(layer_path, &1)) do

          def get_image_count(unquote(layer)), do: unquote(count)
          def get_images_paths(unquote(layer)), do: unquote(images_paths)

          for {image, index} <- images |> Enum.with_index(),
              path = Path.join(layer_path, image) do
                IO.inspect(path)
                def get_image_path_by_index(unquote(layer), unquote(index)), do: unquote(path)
          end
      end
    end
  end
end
