defmodule LcDemo.Monsters do
  @moduledoc """
  The Monsters context.
  """

  import Ecto.Query, warn: false
  alias LcDemo.Repo

  alias LcDemo.Monsters.Monster

  @doc """
  Finds a monster by name.

  ## Examples

      iex> fetch_monster_by_name("Dragon")
      {:ok, %Monster{}}

      iex> get_monster_by_name("NonExistent")
      {:error, :no_such_monster}

  """
  def fetch_monster_by_name(name) do
    term = "%#{name}"
    from(m in Monster, where: ilike(m.name, ^term))
    |> Repo.one()
    |> case do
      %Monster{} = monster -> {:ok, monster}
      _ -> {:error, :no_such_monster}
    end
  end

  @doc """
  Finds monsters by a list of terms in their description (case-insensitive match).

  ## Examples

      iex> find_monsters_by_description(["fire", "water"])
      [%Monster{}, ...]

      iex> find_monsters_by_description(["unknown term", "ghost"])
      []

  """
  def find_monsters_by_description(terms) when is_list(terms) do
    terms = Enum.map(terms, fn term -> "%#{term}%" end)
    query = from(m in Monster)

    Enum.reduce(terms, query, fn term, query ->
      from q in query, or_where: ilike(q.description, ^term)
    end)
    |> Repo.all()
  end

  @doc """
  Creates a monster.

  ## Examples

      iex> create_monster(%{field: value})
      {:ok, %Monster{}}

      iex> create_monster(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_monster(attrs \\ %{}) do
    %Monster{}
    |> Monster.changeset(attrs)
    |> Repo.insert()
  end
end
