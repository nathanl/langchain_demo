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

  @doc """
  Represent the monster in a string that an LLM can understand
  """
  def to_llm_string(%__MODULE__{} = monster) do
    """
    Name: #{monster.name}
    Description: #{monster.description}
    """
  end
end
