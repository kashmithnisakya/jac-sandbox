"""byllm endpoints under scripted MockLLM: deterministic outputs. The
golden pins today's behavior (MockLLM returns the raw scripted string);
prompt-level fidelity is asserted separately once the converter serializes
MTIR metadata."""

from helpers import check_golden, reports_of, result_of


def test_typed_classify(client):
    r = client.post("/walker/Classify", json={"text": "great product"})
    assert r.status_code == 200
    assert reports_of(r.json()) == ['{"label": "positive", "score": 0.9}']
    check_golden("byllm_classify", r.json())


def test_tools_advise(client):
    r = client.post("/walker/Advise", json={"question": "price of ACME?"})
    assert r.status_code == 200
    assert reports_of(r.json()) == [{"answer": '"The answer is 42.5"'}]


def test_prompt_fidelity(client):
    """The exact prompt byllm synthesizes must match the jac start baseline;
    drift means the conversion lost the meaning-typed metadata."""
    r = client.post("/walker/Classify", json={"text": "prompt-fidelity-probe"})
    assert r.status_code == 200

    r = client.post("/function/read_llm_prompts", json={})
    prompts = [
        p for p in result_of(r.json())["prompts"] if "prompt-fidelity-probe" in p
    ]
    assert prompts, "mock never saw the probe prompt"
    check_golden("byllm_prompt", prompts[-1].splitlines())
