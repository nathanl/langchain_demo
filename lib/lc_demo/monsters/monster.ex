defmodule LcDemo.Monsters.Monster do
  use Ecto.Schema
  import Ecto.Changeset

  schema "monsters" do
    field :name, :string
    field :description, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(monster, attrs) do
    monster
    |> cast(attrs, [:name, :description])
    |> validate_required([:name, :description])
  end
end
