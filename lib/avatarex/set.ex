defmodule Avatarex.Set do
  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      @path opts[:path] || raise("missing required option `:renders_path`")
      @keys File.ls!(@path)

      def get_keys, do: @keys
      def get_path, do: @path

      for field <- File.ls!(@path),
          field_path = Path.join(@path, field),
          images = File.ls!(field_path),
          images_paths = Enum.map(images, &Path.join(field_path, &1)),
          count = Enum.count(images) do
        def get_image_count(unquote(field)), do: unquote(count)

        def get_images_paths(unquote(field)), do: unquote(images_paths)

        for {image, index} <- field_path |> File.ls!() |> Enum.with_index(),
            path = Path.join(field_path, image) do
          def get_image_path_by_index(unquote(field), unquote(index)), do: unquote(path)
        end
      end
    end
  end
end
