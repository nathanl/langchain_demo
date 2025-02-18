defmodule LcDemo.Repo.Migrations.CreateMonsters do
  use Ecto.Migration

  def change do
    create table(:monsters) do
      add :name, :string
      add :description, :string

      timestamps(type: :utc_datetime)
    end
  end
end
