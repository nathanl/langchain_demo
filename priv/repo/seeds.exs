# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     LcDemo.Repo.insert!(%LcDemo.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.
alias LcDemo.Repo
alias LcDemo.Monsters.Monster

# List of known monster data with names and descriptions
monsters_data = [
  %{
    name: "Cookie Monster",
    description: "A blue, furry creature from Sesame Street, famous for his love of cookies."
  },
  %{
    name: "Frankenstein's Monster",
    description:
      "A tragic creature stitched together from body parts, often misunderstood and feared."
  },
  %{
    name: "Bigfoot",
    description: "A legendary, large, ape-like creature said to inhabit forests in North America."
  },
  %{
    name: "Loch Ness Monster",
    description:
      "A mysterious creature believed to dwell in Loch Ness, Scotland, often described as a large, serpentine beast."
  },
  %{
    name: "Godzilla",
    description:
      "A massive, radioactive monster from Japan, known for rampaging through cities and battling other kaiju. Comes from the sea."
  },
  %{
    name: "King Kong",
    description:
      "A giant gorilla who battles against other creatures and becomes a symbol of both strength and tragedy."
  },
  %{
    name: "The Mummy",
    description: "An ancient, cursed being wrapped in bandages, brought to life by dark magic."
  },
  %{
    name: "The Werewolf",
    description:
      "A human who transforms into a wolf-like creature during a full moon, driven by primal instincts."
  },
  %{
    name: "Dracula",
    description:
      "A centuries-old vampire, once a prince, now a creature of the night that feeds on blood."
  },
  %{
    name: "Frankenstein's Bride",
    description:
      "The female counterpart to Frankenstein's Monster, brought to life with the same tragic purpose."
  },
  %{
    name: "The Kraken",
    description:
      "A legendary sea monster said to drag ships and sailors into the depths of the ocean."
  },
  %{
    name: "The Yeti",
    description:
      "A large, ape-like creature that roams the mountains of the Himalayas, often mistaken for Bigfoot."
  },
  %{
    name: "The Chupacabra",
    description:
      "A creature from Latin American folklore, known for draining the blood of livestock."
  },
  %{
    name: "Giant Squid",
    description:
      "Not really a monster, but it's huge and scary. Has a giant eyeball and lives in the sea."
  },
  %{
    name: "Jellyfishatron",
    description: "A robot jellyfish who terrorizes all ocean visitors with its incessant humming."
  }
]

# Insert monsters into the database
Enum.each(monsters_data, fn monster_data ->
  %Monster{}
  |> Monster.changeset(monster_data)
  # Ensure no duplicates in case of repeated seeds
  |> Repo.insert!(on_conflict: :nothing)
end)

IO.puts("Known monsters have been seeded successfully!")
