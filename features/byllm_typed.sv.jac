"""Typed by llm(): structured output with sem strings on the function,
its params, and nested object fields. Uses a scripted MockLLM so behavior
is deterministic; the prompt/schema built from these sem strings is the
fidelity surface the conversion must preserve.

Bodies in `features/impl/byllm_typed.impl.jac`. The `sem` strings must stay
on the decl: they are the meaning metadata the prompt is built from."""

import from jaclang.byllm.lib { Model }

glob sentiment_llm: Model = Model(
         model_name="mockllm",
         config={"outputs": ['{"label": "positive", "score": 0.9}'] * 500}
     );

obj Review {
    has label: str;
    has score: float;
}

sem Review.label = "Sentiment label: exactly 'positive' or 'negative'.";
sem Review.score = "Confidence in [0, 1] that the label is correct.";

def classify_review(text: str) -> Review by sentiment_llm();

sem classify_review = "Classify the sentiment of a customer review.";
sem classify_review.text = "The raw review text to classify.";

walker:pub Classify {
    has text: str;

    can go with Root entry;
}

"""Expose the prompts the scripted mock saw: the prompt-drift detector.
The conformance suite pins these against the `jac start` baseline, so a
conversion that loses the meaning-typed metadata fails loudly."""
def:pub read_llm_prompts -> dict;
