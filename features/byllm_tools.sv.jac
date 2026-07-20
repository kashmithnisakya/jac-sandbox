"""by llm() with tools: a ReAct loop over a local tool function, driven by
a scripted MockLLM for determinism.

Bodies in `features/impl/byllm_tools.impl.jac`. `advise` stays body-less
here by design: `by advisor_llm(...)` IS its implementation."""

import from jaclang.byllm.lib { Model }

glob advisor_llm: Model = Model(
         model_name="mockllm", config={"outputs": ['"The answer is 42.5"'] * 500}
     );

def lookup_price(symbol: str) -> str;

sem lookup_price = "Look up the current price for a stock symbol.";

def advise(question: str) -> str by advisor_llm(tools=[lookup_price]);

sem advise = "Answer a finance question, using tools when needed.";

walker:pub Advise {
    has question: str;

    can go with Root entry;
}
