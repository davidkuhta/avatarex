defmodule Avatarex.Example do
  use Avatarex, renders_path: :avatarex |> :code.priv_dir() |> Path.join("renders")

  alias Avatarex.Sets.{Birdy, Kitty}

  for {name, module} <- [birdy: Birdy, kitty: Kitty] do
    set name, module
  end
end