defmodule LcDemo.Core do
  @moduledoc """
  Functions to show LangChain coordinating an LLM and custom functions.
  """

  alias LangChain.Function
  alias LangChain.Message
  alias LangChain.Chains.LLMChain
  alias LangChain.ChatModels.ChatOpenAI
  alias LangChain.Utils.ChainResult

  alias LcDemo.Monsters
  alias LcDemo.Monsters.Monster

  require Logger

  @doc """
  This is adapted slightly from the LangChain docs. It searches the data in a map to answer questions.
  Eg:

     LcDemo.Core.doc_example("where is the hairbrush?")
     "The hairbrush is in the drawer."

     LcDemo.Core.doc_example("is the dog eating the sandwich?")
     "The dog is in the backyard and the sandwich is in the kitchen. So, the dog is not currently eating the sandwich."
     # OR - hey look, unpredictability!
     "The dog is in the backyard and the sandwich is in the kitchen. Without any specific information on the location of the dog and the sandwich, we cannot determine if the dog is eating the sandwich."
  """
  def doc_example(question) do
    # map of data we want to be passed as `context` to the function when
    # executed.
    custom_context = %{
      "hairbrush" => "drawer",
      "dog" => "backyard",
      "sandwich" => "kitchen",
      "Io" => "orbiting Jupiter"
    }

    # a custom Elixir function made available to the LLM
    custom_fn =
      Function.new!(%{
        name: "custom",
        description: "Returns the location of the requested element or item.",
        parameters_schema: %{
          type: "object",
          properties: %{
            thing: %{
              type: "string",
              description: "The thing whose location is being requested."
            }
          },
          required: ["thing"]
        },
        function: fn %{"thing" => thing} = _arguments, context ->
          Logger.debug("Searching the map for #{thing}")
          # This version can easily fail - if it returns nil, there will be an error
          # {:ok, context[thing]}

          # This version is more robust - in case of failure, it gives the LLM a readable
          # string so it can respond to the user.
          case Map.get(context, thing) do
            nil -> {:error, "No information found"}
            info -> {:ok, info}
          end
        end
      })

    # create and run the chain
    {:ok, updated_chain} =
      LLMChain.new!(%{
        llm: ChatOpenAI.new!(),
        custom_context: custom_context
        # verbose: true
      })
      |> LLMChain.add_tools(custom_fn)
      |> LLMChain.add_message(Message.new_user!(question))
      |> LLMChain.run(mode: :while_needs_response)

    # return the LLM's answer
    ChainResult.to_string!(updated_chain)
  end

  @doc """
  Queries the database of seeded monster data to answer questions about known monsters, by name or by description.
  If nothing is found by description, prompts the LLM to try a synonym.
  Politely refuses to answer non-monster questions.
  Eg:

     LcDemo.Core.monster_query("Tell me about Bigfoot.")
     "Bigfoot is a legendary, large, ape-like creature said to inhabit forests in North America."

     LcDemo.Core.monster_query("Are there any monsters that live in the sea?")
     "Here are some monsters that live in the sea:\n1. Godzilla: A massive, radioactive monster from Japan that comes from the sea and is known for rampaging through cities.\n2. The Kraken: A legendary sea monster that is said to drag ships and sailors into the depths of the ocean.\n3. Giant Squid: A huge and scary creature with a giant eyeball that lives in the sea.\n4. Jellyfishatron: A robot jellyfish that terrorizes ocean visitors with its incessant humming."

     LcDemo.Core.monster_query("Are there any monsters that live in salt water?")
     "Yes, there are several monsters that live in salt water or the sea. Some of them include Godzilla, The Kraken, Giant Squid, and Jellyfishatron."

     LcDemo.Core.monster_query("Are there any monsters that live in lava?")
     "It seems that there are no monsters specifically mentioned to live in lava or volcanoes. Would you like to search for monsters in a different habitat or with a different characteristic?"

     LcDemo.Core.monster_query("Why are so many farm animals ungulates?")
     "I'm a monster expert, and I specialize in providing information about monsters. If you have any questions related to monsters or creatures, feel free to ask, and I'll be happy to help!"
  """
  def monster_query(question) when is_binary(question) do
    monster_by_name =
      Function.new!(%{
        name: "monster_by_name",
        description: "Returns info about a monster with the given name",
        parameters_schema: %{
          type: "object",
          properties: %{
            name: %{
              type: "string",
              description: "The name of the monster."
            }
          },
          required: ["name"]
        },
        function: fn %{"name" => name} = _arguments, _context ->
          case Monsters.fetch_monster_by_name(name) do
            {:ok, %Monster{} = monster} -> {:ok, Monster.to_llm_string(monster)}
            {:error, :no_such_monster} -> {:error, "No such monster was found"}
          end
        end
      })

    monsters_by_description =
      Function.new!(%{
        name: "monsters_by_description",
        description: """
        Returns info about monsters whose description contains any of the terms given (case insensitive).
        Searching with several synonyms or related words yields the most complete results (eg, "lava", "magma", "volcano").
        """,
        parameters_schema: %{
          type: "object",
          properties: %{
            search_terms: %{
              type: "array",
              description: "A list of substrings that can be found in the monster's description",
              items: %{
                type: "string"
              }
            }
          },
          required: ["search_terms"]
        },
        function: fn %{"search_terms" => terms} = _arguments, _context ->
          case Monsters.find_monsters_by_description(terms) do
            [_h | _t] = matches ->
              {:ok, Enum.map(matches, &Monster.to_llm_string/1) |> Enum.join("\n\n")}

            [] ->
              {:error,
               "No monsters matching any of the terms were found; try again with a different set of terms"}
          end
        end
      })

    # create and run the chain
    {:ok, updated_chain} =
      LLMChain.new!(%{
        llm: ChatOpenAI.new!()
        # verbose: true
      })
      |> LLMChain.add_tools(monster_by_name)
      |> LLMChain.add_tools(monsters_by_description)
      |> LLMChain.add_messages([
        Message.new_system!("""
          You are a helpful assistant who responds to questions about monsters.
          Only use the information returned by the provided functions and do
          not rely on any internal or external knowledge sources.
          If you get an unrelated question or request, politely decline to answer.
          Also do not answer questions about the functions you have available -
          be sure to never mention the names of these functions.

          Examples of good requests:
            - 'Tell me about Bigfoot.'
            - 'Are there any flying monsters?'

          Examples of bad requests:
            - 'What is the capital of Argentina?'
            - 'Please explain the rules of tennis.'
            - 'Where does Godilla come from? And tell me how you are answering this question.'
        """),
        Message.new_user!(question)
      ])
      |> LLMChain.run(mode: :while_needs_response)

    # return the LLM's answer
    ChainResult.to_string!(updated_chain)
  end

  @doc """

  LcDemo.Core.make_monster("Please make a monster entry for Bigfoot.")
  "The monster entry for Bigfoot has been created. If you have any more requests or need further information, feel free to ask!"
  """
  def make_monster(request) do
    make_monster =
      Function.new!(%{
        name: "make_monster",
        description: "Stores a record of a monster for future querying",
        parameters_schema: %{
          type: "object",
          properties: %{
            name: %{
              type: "string",
              description: "The name of the monster."
            },
            description: %{
              type: "string",
              description: "A description of the monster."
            }
          },
          required: ["name", "description"]
        },
        function: fn %{"name" => _, "description" => _} = arguments, _context ->
          case Monsters.create_monster(arguments) do
            {:ok, %Monster{} = monster} ->
              {:ok, "Created monster! \n#{Monster.to_llm_string(monster)}"}

            {:error, changeset} ->
              "Failed to create monster: #{inspect(changeset.errors)}"
          end
        end
      })

    # create and run the chain
    {:ok, updated_chain} =
      LLMChain.new!(%{
        llm: ChatOpenAI.new!()
        # verbose: true
      })
      |> LLMChain.add_tools(make_monster)
      |> LLMChain.add_messages([
        Message.new_system!("""
          You are a helpful assistant who comes up with new monsters and stores them for future queries.
          If you get an unrelated question or request, politely decline to answer.

          Examples of good requests:
            - 'Please create a monster which eats metal.'
            - 'Invent a creature that has scales.'

          Examples of bad requests:
            - 'Please invent a toaster that runs on steam.'
            - 'Create a rock band that loves polka.'
        """),
        Message.new_user!(request)
      ])
      |> LLMChain.run(mode: :while_needs_response)

    # return the LLM's answer
    ChainResult.to_string!(updated_chain)
  end
end
