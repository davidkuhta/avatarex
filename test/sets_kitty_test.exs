defmodule SetsKittyTest do
  use ExUnit.Case

  alias Avatarex.Sets.Kitty

  doctest Kitty

  setup_all do
    [ 
      fields: ~w[body eye fur mouth accessorie],
      counts: [15, 15, 10, 10, 20]
    ]
  end

  test "get keys", %{fields: fields} do
    assert Kitty.get_keys() == fields
  end

  test "get path" do
    assert Kitty.get_path() =~ "avatarex/priv/sets/kitty"
  end

  test "get image count", %{fields: fields, counts: counts} do
    for {f, c} <- Enum.zip(fields, counts) do
      assert Kitty.get_image_count(f) == c
    end
  end

  test "get images paths", %{fields: fields} do
    for f <- fields do
      for path <- Kitty.get_images_paths(f) do
        assert path =~ "avatarex/priv/sets/kitty/#{f}"
      end
    end
  end

  test "get image path by index", %{fields: fields, counts: counts} do
    base_path = "avatarex/priv/sets/kitty"
    for {f, c} <- Enum.zip(fields, counts) do
      for i <- 0..c-1 do
        assert Kitty.get_image_path_by_index(f, i) =~ "#{base_path}/#{f}/#{f}_"
      end
    end
  end
end