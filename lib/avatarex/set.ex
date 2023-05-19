defmodule Avatarex.Set do
  @moduledoc """
  This module provides functions for creating an `Avatarex.Set`

  Optional parameters:
  
    path: The root path or path relative to 'priv/sets' in which to find the feature
    folders for the set. Will default to "avatarex/priv/sets/module" if parameter not provided.

    layer_order: A word list of the features corresponding to the folders for the set.
    Order corresponds to the rendering order [base -> final]. Defaults to the ls for the
    set directory if parameter not provided.

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
  @moduledoc since: "0.1.0"

  @spec __using__([opts: String.t]) :: Macro.t
  defmacro __using__(opts) do

    quote bind_quoted: [opts: opts] do

      # @path opts[:path] || Avatarex.set_dir(__MODULE__)
      @path (case opts[:path] do
        nil -> Avatarex.set_dir(__MODULE__)
        path -> if File.exists?(path), do: path, else: Avatarex.set_dir(path)
      end)
      
      @keys (case opts[:layer_order] do
        nil -> File.ls!(@path)
        {:sigil_w, _, [{_, _, [keys]}, _]} -> keys
        keys -> keys
      end)

      @doc """
      Returns keys for the set.
      """
      @spec get_keys() :: keys :: [String.t]
      def get_keys, do: @keys

      @doc """
      Returns the path to the set.
      """
      @spec get_path() :: path :: String.t
      def get_path, do: @path


      @doc """
      Returns the count of images for a given field in the set.
      """
      @spec get_image_count(String.t) :: image_count :: integer
      for field <- @keys,
          count = @path |> Path.join(field) |> File.ls!() |> Enum.count() do
        def get_image_count(unquote(field)), do: unquote(count)
      end

      @doc """
      Returns the path of images for a given field in the set.
      """
      @spec get_images_paths(String.t) :: field_images_path :: [String.t]
      for field <- @keys,
          field_path = Path.join(@path, field),
          images = File.ls!(field_path),
          images_paths = Enum.map(images, &Path.join(field_path, &1)) do
        def get_images_paths(unquote(field)), do: unquote(images_paths)
      end


      @doc """
      Returns the path for a particular image of a given field in the set.
      """
      @spec get_image_path_by_index(String.t, integer) :: field_image_path_for_index :: String.t
      for field <- @keys,
          field_path = Path.join(@path, field),
          images = File.ls!(field_path) do

        for {image, index} <- images |> Enum.with_index(),
            path = Path.join(field_path, image) do

          def get_image_path_by_index(unquote(field), unquote(index)), do: unquote(path)
        end
      end

    end
  end
end
