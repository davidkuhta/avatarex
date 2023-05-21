defmodule AvatarexTest do
  use ExUnit.Case

  Logger.configure(level: :warn)

  alias Avatarex.Sets.{Birdy, Kitty}
  
  doctest Avatarex

  setup_all do
    [
      renders_path: Path.join(File.cwd!, "priv/renders")
    ]
  end

  sets = [
    birdy: %{set: Birdy, layers: ~w[body hoop tail wing eyes bec accessorie]},
    kitty: %{set: Kitty, layers: ~w[body eye fur mouth accessorie]},
  ]

  for {name, %{set: set, layers: layers}} <- sets do

    test "generates #{name} avatar", context do
      avatar_random = Avatarex.random(unquote(set), unquote(name), context[:renders_path])
      avatar_named = Avatarex.generate("test_#{unquote(name)}",
                                  unquote(set), unquote(name), context[:renders_path])
      assert avatar_named.name == "test_#{unquote(name)}"
      assert is_integer(avatar_random.name)
      for avatar <- [avatar_random, avatar_named] do
        assert avatar.image == nil
        assert avatar.set == unquote(name)
        assert avatar.renders_path == context[:renders_path]
        for {layer, path} <- avatar.images do
          assert Enum.member?(unquote(layers), layer)
          assert path =~ "priv/sets/#{unquote(name)}/#{layer}/#{layer}_"
        end
        assert Enum.count(avatar.images) == Enum.count(unquote(layers))
      end
    end

    test "renders generated #{name} avatar", context do
      avatar_random = Avatarex.random(unquote(set), unquote(name), context[:renders_path])
      avatar_named = Avatarex.generate("test_#{unquote(name)}",
                                  unquote(set), unquote(name), context[:renders_path])
      for avatar <- [avatar_random, avatar_named] do
        rendered = Avatarex.render(avatar)
        assert %Vix.Vips.Image{} = rendered.image
      end
    end

    test "renders ungenerated #{name} avatar", context do
      rendered_random = Avatarex.render(unquote(set), unquote(name), context[:renders_path])
      rendered_named = Avatarex.render("test_#{unquote(name)}",
                                  unquote(set), unquote(name), context[:renders_path])
      for rendered <- [rendered_random, rendered_named] do
        assert %Vix.Vips.Image{} = rendered.image
      end
    end

    test "writes #{name} avatar", context do
      avatar_random = Avatarex.random(unquote(set), unquote(name), context[:renders_path])
      avatar_named = Avatarex.generate("test_#{unquote(name)}",
                                  unquote(set), unquote(name), context[:renders_path])
      for rendered <- [avatar_random, avatar_named] do
        file_name = "#{rendered.name}_#{unquote(name)}.png"
        renders_path = context[:renders_path]
        files = File.ls!(renders_path)
        refute file_name in files
        count = Enum.count(files)
        Avatarex.write(rendered)
        files = File.ls!(renders_path)
        assert Enum.count(files) == count + 1
        assert file_name in files

        on_exit(fn -> File.rm!(Path.join(rendered.renders_path, file_name)) end)
      end
    end
  end
end
