defmodule LcDemo do
  alias LangChain.Function
  alias LangChain.Message
  alias LangChain.Chains.LLMChain
  alias LangChain.ChatModels.ChatOpenAI
  alias LangChain.Utils.ChainResult

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
end
