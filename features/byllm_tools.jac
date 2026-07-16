"""by llm() with tools: a ReAct loop over a local tool function, driven by
a scripted MockLLM for determinism."""

import from jaclang.byllm.lib { Model }

glob advisor_llm: Model = Model(
    model_name="mockllm",
    config={"outputs": ['"The answer is 42.5"'] * 500}
);

def lookup_price(symbol: str) -> str {
    return "42.5";
}

sem lookup_price = "Look up the current price for a stock symbol.";

def advise(question: str) -> str by advisor_llm(tools=[lookup_price]);

sem advise = "Answer a finance question, using tools when needed.";

walker:pub Advise {
    has question: str;

    can go with Root entry {
        report {"answer": advise(self.question)};
    }
}
