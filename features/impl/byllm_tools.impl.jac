"""Bodies for `features/byllm_tools.sv.jac`.

`advise` is absent here on purpose: an llm-backed decl has no impl annex.
Its `sem` strings stay on the decl, where the prompt builder reads them."""

impl lookup_price(symbol: str) -> str {
    return "42.5";
}

impl Advise.go with Root entry {
    report {"answer": advise(self.question)};
}
