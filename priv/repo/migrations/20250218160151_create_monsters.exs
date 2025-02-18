defmodule LcDemo.Repo.Migrations.CreateMonsters do
  use Ecto.Migration

  def change do
    create table(:monsters) do
      add :name, :string, null: false
      add :description, :text, null: false

      timestamps(type: :utc_datetime)
    end
  end
end
