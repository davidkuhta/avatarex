defmodule Avatarex.Birdy do
  @moduledoc """
  The Birdy module generates Birdy avatars using images created
  by David Revoy and used under CC-BY-4.0.

  https://www.davidrevoy.com/article591/cat-bird-fenestar-abstract-avatar-generators
  """
  @moduledoc since: "1.0.0"
  use AvatarexSet, 
    dir: "priv/sets/birdy",
    keys: [:body, :hoop, :tail, :wing, :eyes, :bec, :accessorie]
end