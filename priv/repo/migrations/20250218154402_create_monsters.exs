defmodule LcDemo.Repo.Migrations.CreateMonsters do
  use Ecto.Migration

  def change do
    create table(:monsters) do
      add :name, :string, null: false
      add :description, :text, null: false
    end
  end
end
