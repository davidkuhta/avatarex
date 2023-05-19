defmodule Avatarex.Sets.Kitty do
  @moduledoc """
  This module generates kitten avatars using images created
  by David Revoy and used under CC-BY-4.0.

  https://www.davidrevoy.com/article591/cat-bird-fenestar-abstract-avatar-generators
  """
  @moduledoc since: "0.1.0"

  use Avatarex.Set, path: "kitty", layer_order: ~w[body eye fur mouth accessory]
end
