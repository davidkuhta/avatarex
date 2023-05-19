defmodule SetsBirdyTest do
  use ExUnit.Case

  alias Avatarex.Sets.Birdy

  doctest Birdy

  setup_all do
    [ 
      fields: ~w[body hoop tail wing eyes bec accessorie],
      counts: [9, 10, 9, 9, 9, 9, 20]
    ]
  end

  test "get keys", %{fields: fields} do
    assert Birdy.get_keys() == fields
  end

  test "get path" do
    assert Birdy.get_path() =~ "avatarex/priv/sets/birdy"
  end

  test "get image count", %{fields: fields, counts: counts} do
    for {f, c} <- Enum.zip(fields, counts) do
      assert Birdy.get_image_count(f) == c
    end
  end

  test "get images paths", %{fields: fields} do
    for f <- fields do
      for path <- Birdy.get_images_paths(f) do
        assert path =~ "avatarex/priv/sets/birdy/#{f}"
      end
    end
  end

  test "get image path by index", %{fields: fields, counts: counts} do
    base_path = "avatarex/priv/sets/birdy"
    for {f, c} <- Enum.zip(fields, counts) do
      for i <- 0..c-1 do
        assert Birdy.get_image_path_by_index(f, i) =~ "#{base_path}/#{f}/#{f}_"
      end
    end
  end
end
