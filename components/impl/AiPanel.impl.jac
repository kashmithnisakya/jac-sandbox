"""Handlers for `components/AiPanel.cl.jac`."""

impl AiPanel.run(probe: str) -> None {
    busy = True;
    started = Date.now();
    try {
        # `as any`: walkers report a list, read_llm_prompts returns a dict —
        # without the cast the checker narrows `body` to the first branch.
        body: any = None;
        if probe == "classify" {
            body = (root spawn Classify(text=review)).reports as any;
        } elif probe == "advise" {
            body = (root spawn Advise(question=question)).reports as any;
        } elif probe == "prompts" {
            body = await read_llm_prompts() as any;
        }
        out = Res(ok=True, ms=int(Date.now() - started), body=body);
    } except Exception as e {
        out = Res(ok=False, ms=int(Date.now() - started), body={"error": str(e)});
    }
    busy = False;
}
