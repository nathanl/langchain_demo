# LcDemo

A demo of using LangChain to let ChatGPT answer questions by calling custom functions, including database queries.

## Requirements

Set `"OPENAI_API_KEY"` env var, possibly by using `.envrc` (see `.envrc.example`).

## Usage

Do the above, then run `iex -S mix` and play with:

- `LcDemo.doc_example/1`
- `LcDemo.monster_query/1`.
