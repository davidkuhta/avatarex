defmodule Avatarex.Example do
  @moduledoc """
  Avatarex.Example is an example to demonstrate how use Avatarex to create avatars.

  This involves using the `Avatarex` module and invoking the `Avatarex.set/2` macro for
  each: set name, module.
  """
  @moduledoc since: "0.1.1"

  use Avatarex

  alias Avatarex.Sets.{Birdy, Kitty}

  for {name, module} <- [birdy: Birdy, kitty: Kitty] do
    set name, module
  end
end