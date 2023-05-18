defmodule Avatarex.Set do
  @moduledoc """
  This module provides functions for creating an `Avatarex.Set`

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

  defmacro __using__(opts) do

    quote bind_quoted: [opts: opts] do

      @path opts[:path] || Avatarex.set_dir(__MODULE__)
      
      @keys (case opts[:layer_order] do
        nil -> File.ls!(@path)
        {:sigil_w, _, [{_,_,[keys]}, _]} -> keys
        keys -> keys
      end)

      @doc """
      Returns keys for the set.
      """
      def get_keys, do: @keys

      @doc """
      Returns the path to the set.
      """
      def get_path, do: @path

      for field <- @keys,
          field_path = Path.join(@path, field),
          images = File.ls!(field_path),
          images_paths = Enum.map(images, &Path.join(field_path, &1)),
          count = Enum.count(images) do


        @doc """
        Returns the count of images for a given field in the set.
        """
        def get_image_count(unquote(field)), do: unquote(count)

        @doc """
        Returns the path of images for a given field in the set.
        """
        def get_images_paths(unquote(field)), do: unquote(images_paths)

        for {image, index} <- field_path |> File.ls!() |> Enum.with_index(),
            path = Path.join(field_path, image) do

          @doc """
          Returns the path for a particular image of a given field in the set.
          """
          def get_image_path_by_index(unquote(field), unquote(index)), do: unquote(path)
        end
      end
    end
  end
end
