defmodule Avatarex.TestAvatar do
  @moduledoc """
  Avatarex.TestAvatar is an example to demonstrate how use Avatarex to create avatars.

  This involves using the `Avatarex` module and invoking the `Avatarex.set/2` macro for
  each: set name, module.
  """

  use Avatarex

  alias Avatarex.Sets.{Birdy, Kitty}

  for {name, module} <- [birdy: Birdy, kitty: Kitty] do
    set name, module
  end
end