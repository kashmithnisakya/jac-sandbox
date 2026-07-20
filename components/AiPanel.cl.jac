"""AI panel: typed `by llm()` output and a `by llm()` tool loop.

Both walkers are backed by a scripted MockLLM, so the answers are fixed and
boring by design — the bench is pinning prompt construction, not model quality.
`read_llm_prompts()` is the interesting button: it shows the prompt the model
actually saw, built from the `sem` strings, and that text is what the
conversion has to reproduce byte-for-byte."""

sv import from features.byllm_typed { Classify, read_llm_prompts }
sv import from features.byllm_tools { Advise }

import from .Bench { Panel, Row, TextInput, RunButton, ResultView, Res, statusOf }

def:pub AiPanel -> JsxElement {
    has review: str = "this product is wonderful",
        question: str = "What is the price of ACME?",
        out: any = None,
        busy: bool = False;

    async def run(probe: str) -> None;

    return
        <Panel
            title="by llm(): typed output + tools"
            blurb="Scripted MockLLM, so output is deterministic. read_llm_prompts() exposes the prompt built from the sem strings — the prompt-fidelity surface."
            wire="POST /walker/Classify | /walker/Advise | /function/read_llm_prompts"
            status={statusOf(out)}
        >
            <Row>
                <TextInput
                    value={review}
                    onChange={lambda (e: any) { review = e.target.value; }}
                    placeholder="review text"
                    width="20rem"
                />
                <RunButton
                    label="Classify"
                    onClick={lambda { run("classify"); }}
                    busy={busy}
                />
            </Row>
            <Row>
                <TextInput
                    value={question}
                    onChange={lambda (e: any) { question = e.target.value; }}
                    placeholder="finance question"
                    width="20rem"
                />
                <RunButton
                    label="Advise (tool loop)"
                    onClick={lambda { run("advise"); }}
                    busy={busy}
                />
            </Row>
            <Row>
                <RunButton
                    label="read_llm_prompts()"
                    onClick={lambda { run("prompts"); }}
                    busy={busy}
                    tone="ghost"
                />
            </Row>
            <ResultView value={out}/>
        </Panel>;
}
