# LcDemo

A demo of using LangChain to let ChatGPT answer questions by calling custom functions, including database queries.
See `LcDemo.doc_example/1` and `LcDemo.monster_query/1`.

## Requirements

Set `"OPENAI_API_KEY"` env var.

## TODO

- Ensure that the LLM will not answer questions unrelated to our subject matter. (It seems to be ignoring the prompt about that.)
