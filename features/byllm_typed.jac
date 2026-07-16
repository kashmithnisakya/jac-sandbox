"""Typed by llm(): structured output with sem strings on the function,
its params, and nested object fields. Uses a scripted MockLLM so behavior
is deterministic; the prompt/schema built from these sem strings is the
fidelity surface the conversion must preserve."""

import from jaclang.byllm.lib { Model }

glob sentiment_llm: Model = Model(
    model_name="mockllm",
    config={"outputs": ['{"label": "positive", "score": 0.9}']}
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

    can go with Root entry {
        report classify_review(self.text);
    }
}
