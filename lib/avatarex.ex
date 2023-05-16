defmodule Avatarex do
  @moduledoc """
  Documentation for `Avatarex`.
  """

  alias Avatarex.Kitty

  @doc """
  Generates a random kitty avatar

  ## Examples

      iex> Avatarex.hello()
      :world

  """
  def kitty(string) do
    hash(string)
    |> Kitty.generate()
    |> IO.inspect()
    |> Kitty.render()
  end

  def kitty() do
    Kitty.random("random")
  end

  def hash(avatar_string) when is_binary(avatar_string) do
    :crypto.hash(:sha512, avatar_string) 
  end
end
