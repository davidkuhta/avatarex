defmodule Avatarex do
  @moduledoc """
  `Avatarex` is inspired by Robohash: https://github.com/e1ven/Robohash

  Two Avatar sets are provided `Avatarex.Birdy` and `Avatarex.Kitty`

  """
  @moduledoc since: "0.1.0"

  alias Avatarex.{Birdy, Kitty}

  @doc """
  Generates an avatar for a given name and Avatar type.
  Defaults to :kitty

  ## Examples

      iex> Avatarex.generate("oscar", :birdy)
      %Avatarex.Birdy{name: oscar}

  """
  def generate(name, set \\ :kitty) when set in [:kitty, :birdy] and is_binary(name) do
    case set do
      :birdy -> birdy(name)
      :kitty -> kitty(name)
    end
  end

  @doc """
  Generates an `AvatarexKitty` avatar constructed
  using the hash of the given name.

  ## Examples

      iex> Avatarex.kitty(name)
      %Avatarex.Kitty{name: name, ...}

  """
  def kitty(string) do
    kitty = string
    |> Kitty.generate()
    Kitty.render(kitty)
    kitty
  end

  @doc """
  Generates a random kitty avatar

  ## Examples

      iex> Avatarex.kitty()
      %Avatarex.Kitty{}

  """
  def kitty() do
    Kitty.random()
  end

  @doc """
  Generates an `AvatarexKitty` avatar constructed
  using the hash of the given name.

  ## Examples

      iex> Avatarex.birdy(name)
      %Avatarex.Birdy{name: name, ...}

  """
  def birdy(string) do
    birdy = string
    |> Birdy.generate()
    Birdy.render(birdy)
    birdy
  end

  @doc """
  Generates a random birdy avatar

  ## Examples

      iex> Avatarex.birdy()
      %Avatarex.Birdy{}

  """
  def birdy() do
    Birdy.random()
  end

  @doc """
  Generates a hash for a given string using sha512 from 
  Erlang's crypto module.

  ## Examples

      iex> Avatarex.hash("avatar_name")
      <<130, 249, 176, 138, 182, 111, 225, 152, 83, 237, ... >>

  """
  def hash(avatar_string) when is_binary(avatar_string) do
    :crypto.hash(:sha512, avatar_string) 
  end
end
