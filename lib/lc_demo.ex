defmodule LcDemo do
  alias LangChain.Function
  alias LangChain.Message
  alias LangChain.Chains.LLMChain
  alias LangChain.ChatModels.ChatOpenAI
  alias LangChain.Utils.ChainResult

  alias LcDemo.Monsters
  alias LcDemo.Monsters.Monster

  @doc """
  This is taken from the LangChain docs. It searches the data in a map to answer questions.
  Eg:

     doc_example("where is the hairbrush?")
     "The hairbrush is in the drawer."

     doc_example("is the dog eating the sandwich?")
     "The dog is in the backyard and the sandwich is in the kitchen. So, the dog is not currently eating the sandwich."
     # OR - hey look unpredictability
     "The dog is in the backyard and the sandwich is in the kitchen. Without any specific information on the location of the dog and the sandwich, we cannot determine if the dog is eating the sandwich."
  """
  def doc_example(question) do
    # map of data we want to be passed as `context` to the function when
    # executed.
    custom_context = %{
      "user_id" => 123,
      "hairbrush" => "drawer",
      "dog" => "backyard",
      "sandwich" => "kitchen"
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
          # our context is a pretend item/location location map
          {:ok, context[thing]}
        end
      })

    # create and run the chain
    {:ok, updated_chain} =
      LLMChain.new!(%{
        llm: ChatOpenAI.new!(),
        custom_context: custom_context,
        verbose: true
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
  Eg:

     monster_query("Tell me about Bigfoot.")
     "Bigfoot is a legendary, large, ape-like creature said to inhabit forests in North America."

     LcDemo.monster_query("Are there any monsters that live in the sea?")
     "Here are some monsters that live in the sea:\n\n1. **Godzilla**: A massive, radioactive monster from Japan, known for rampaging through cities and battling other kaiju. Comes from the sea.\n\n2. **The Kraken**: A legendary sea monster said to drag ships and sailors into the depths of the ocean.\n\n3. **Giant Squid**: Although not considered a traditional monster, the giant squid is huge and scary. It has a giant eyeball and lives in the sea."

     LcDemo.monster_query("Are there any monsters that live in salt water?")
     "I found two monsters related to the ocean:\n\n1. **The Kraken**: A legendary sea monster said to drag ships and sailors into the depths of the ocean.\n2. **Jellyfishatron**: A robot jellyfish who terrorizes all ocean visitors with its incessant humming.\n\nThese monsters have a connection to the ocean."

     LcDemo.monster_query("Are there any monsters that live in lava?")
     "It seems that there are no monsters specifically mentioned to live in lava or volcanoes. Would you like to search for monsters in a different habitat or with a different characteristic?"
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
        description: "Returns info about monsters whose description contains the term given (case insensitive). If nothing is found with a given search term, or if you want more results, try a synonym or related word. For example, 'sky', 'air', 'flying'.",
        parameters_schema: %{
          type: "object",
          properties: %{
            search_term: %{
              type: "string",
              description: "A substring that can be found in the monster's description"
            }
          },
          required: ["search_term"]
        },
        function: fn %{"search_term" => term} = _arguments, _context ->
          case Monsters.find_monsters_by_description(term) do
            [_h | _t] = matches ->
              {:ok, Enum.map(matches, &Monster.to_llm_string/1) |> Enum.join("\n\n")}

            [] -> {:error, "No monsters matching this term were found, but a synonym might find something"}
          end
        end
      })

    # create and run the chain
    {:ok, updated_chain} =
      LLMChain.new!(%{
        llm: ChatOpenAI.new!(),
        verbose: true,
        messages: [LangChain.Message.new_system!(
          """
          You are a helpful assistant who responds to queries about monsters.
          Do not answer questions about anything else.
          Don't speculate when you can't find any information.
          """
        )]
      })
      |> LLMChain.add_tools(monster_by_name)
      |> LLMChain.add_tools(monsters_by_description)
      |> LLMChain.add_message(Message.new_user!(question))
      |> LLMChain.run(mode: :while_needs_response)

    # return the LLM's answer
    ChainResult.to_string!(updated_chain)
  end
end
