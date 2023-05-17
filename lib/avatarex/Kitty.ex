defmodule Avatarex.Kitty do
  @moduledoc """
  This module generates Cat avatars using images created
  by David Revoy and used under CC-BY-4.0.

  https://www.davidrevoy.com/article591/cat-bird-fenestar-abstract-avatar-generators
  """
  @moduledoc since: "0.1.0"

  use Avatarex.Set, 
    set_dir: ~w[sets kitty],
    keys: ~w[body eye fur mouth accessory]a
end