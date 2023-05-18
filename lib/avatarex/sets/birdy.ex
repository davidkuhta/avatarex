defmodule Avatarex.Sets.Birdy do
  @moduledoc """
  This module generates bird avatars using images created
  by David Revoy and used under CC-BY-4.0.

  https://www.davidrevoy.com/article591/cat-bird-fenestar-abstract-avatar-generators
  """
  @moduledoc since: "0.1.0"

  use Avatarex.Set, layer_order: ~w[body hoop tail wing eyes bec accessorie]
end
