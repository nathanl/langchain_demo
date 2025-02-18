defmodule LcDemo.Monsters do
  @moduledoc """
  The Monsters context.
  """

  import Ecto.Query, warn: false
  alias LcDemo.Repo

  alias LcDemo.Monsters.Monster

  @doc """
  Returns the list of monsters.

  ## Examples

      iex> list_monsters()
      [%Monster{}, ...]

  """
  def list_monsters do
    Repo.all(Monster)
  end

  @doc """
  Gets a single monster.

  Raises `Ecto.NoResultsError` if the Monster does not exist.

  ## Examples

      iex> get_monster!(123)
      %Monster{}

      iex> get_monster!(456)
      ** (Ecto.NoResultsError)

  """
  def get_monster!(id), do: Repo.get!(Monster, id)

  @doc """
  Finds a monster by name.

  ## Examples

      iex> fetch_monster_by_name("Dragon")
      {:ok, %Monster{}}

      iex> get_monster_by_name("NonExistent")
      {:error, :no_such_monster}

  """
  def fetch_monster_by_name(name) do
    Repo.get_by(Monster, name: name)
    |> case do
      %Monster{} = monster -> {:ok, monster}
      _ -> {:error, :no_such_monster}
    end
  end

  @doc """
  Finds monsters by a term in their description (case-insensitive match).

  ## Examples

      iex> find_monsters_by_description("fire")
      [%Monster{}, ...]

      iex> find_monsters_by_description("unknown term")
      []

  """
  def find_monsters_by_description(term) do
    Repo.all(from m in Monster, where: ilike(m.description, ^"%#{term}%"))
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

  @doc """
  Updates a monster.

  ## Examples

      iex> update_monster(monster, %{field: new_value})
      {:ok, %Monster{}}

      iex> update_monster(monster, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_monster(%Monster{} = monster, attrs) do
    monster
    |> Monster.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a monster.

  ## Examples

      iex> delete_monster(monster)
      {:ok, %Monster{}}

      iex> delete_monster(monster)
      {:error, %Ecto.Changeset{}}

  """
  def delete_monster(%Monster{} = monster) do
    Repo.delete(monster)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking monster changes.

  ## Examples

      iex> change_monster(monster)
      %Ecto.Changeset{data: %Monster{}}

  """
  def change_monster(%Monster{} = monster, attrs \\ %{}) do
    Monster.changeset(monster, attrs)
  end
end
