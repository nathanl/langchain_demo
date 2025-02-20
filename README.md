# LcDemo

A demo of using LangChain to let ChatGPT answer questions by calling custom functions, including database queries.

## Setup

- Set a valid `"OPENAI_API_KEY"` env var, possibly by using `.envrc` (see `.envrc.example`).
- `mix ecto.setup`

## Usage

Do the above, then run `iex -S mix` and play with:

- `LcDemo.doc_example/1`
- `LcDemo.monster_query/1`.

## What Is this Magic?

I asked ChatGPT, and it said that what LangChain does is "tool augmentation or agent-based interaction."

> ## How It Works in Practice:
- **Prompting the Model**: The model is given a prompt that not only includes the current conversation but also a description of available functions (e.g., “updateDatabase” or “queryDatabase”).
- **Deciding to Act**: Based on the conversation context, the model determines that it needs to perform an action rather than just generate text.
- **Generating a Function Call**: The model outputs a command in a structured format that specifies which function to call and with what parameters.
- **Executing and Returning Results**: LangChain or your custom middleware intercepts this command, executes the corresponding function, and then provides the output back into the conversation.
- **Continuing the Dialogue**: The model uses this returned data to inform further responses.
