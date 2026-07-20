"""Bodies for `features/byllm_typed.sv.jac`."""

impl Classify.go with Root entry {
    report classify_review(self.text);
}

impl read_llm_prompts -> dict {
    mock = sentiment_llm._mock_delegate
        if getattr(sentiment_llm, "_mock_delegate", None)
        else sentiment_llm;
    return {"prompts": [str(p) for p in getattr(mock, "seen_prompts", [])]};
}
