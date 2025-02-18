defmodule LcDemo.MonstersFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `LcDemo.Monsters` context.
  """

  @doc """
  Generate a monster.
  """
  def monster_fixture(attrs \\ %{}) do
    {:ok, monster} =
      attrs
      |> Enum.into(%{
        description: "some description",
        name: "some name"
      })
      |> LcDemo.Monsters.create_monster()

    monster
  end
end
