defmodule Avatarex.Sets.Kitty do
  @moduledoc """
  This module generates kitten avatars using images created
  by David Revoy and used under CC-BY-4.0.

  https://www.davidrevoy.com/article591/cat-bird-fenestar-abstract-avatar-generators
  """
  
  use Avatarex.Set, layer_order: ~w[body eye fur mouth accessorie]
end
