defmodule LcDemo do
  alias LangChain.Function
  alias LangChain.Message
  alias LangChain.Chains.LLMChain
  alias LangChain.ChatModels.ChatOpenAI
  alias LangChain.Utils.ChainResult

  alias LcDemo.Monsters
  alias LcDemo.Monsters.Monster

  def doc_example do
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
      |> LLMChain.add_message(Message.new_user!("is the dog eating the sandwich?"))
      |> LLMChain.run(mode: :while_needs_response)

    # print the LLM's answer
    IO.puts(ChainResult.to_string!(updated_chain))
    # => "The hairbrush is located in the drawer."
  end

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
        description: "Returns info about monsters whose description contains the term given (case insensitive)",
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

            [] -> {:error, "No monsters matching this term were found"}
          end
        end
      })

    # create and run the chain
    {:ok, updated_chain} =
      LLMChain.new!(%{
        llm: ChatOpenAI.new!(),
        verbose: true
      })
      |> LLMChain.add_tools(monster_by_name)
      |> LLMChain.add_tools(monsters_by_description)
      |> LLMChain.add_message(Message.new_user!(question))
      |> LLMChain.run(mode: :while_needs_response)

    # print the LLM's answer
    IO.puts(ChainResult.to_string!(updated_chain))
    # => "The hairbrush is located in the drawer."
  end
end
