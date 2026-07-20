"""Handlers for `components/ScalePanel.cl.jac`.

KvPut/KvGet are expected to come back `ok=false` with an EXECUTION_ERROR body
on a bare local run — the kvstore wants redis. That is a documented baseline,
not a panel bug, so the error is rendered rather than hidden."""

impl ScalePanel.run(probe: str) -> None {
    busy = True;
    started = Date.now();
    try {
        # `as any` on every branch: a walker reports a list and a function
        # returns a dict, and without the cast the checker narrows `body` to
        # whichever branch it reads first, then rejects the others (E1001).
        body: any = None;
        if probe == "emit" {
            body = (root spawn EmitEvent(payload=payload)).reports as any;
        } elif probe == "read_events" {
            body = await read_events() as any;
        } elif probe == "kv_put" {
            body = (root spawn KvPut(key=key, value=value)).reports as any;
        } elif probe == "kv_get" {
            body = (root spawn KvGet(key=key)).reports as any;
        } elif probe == "heartbeat" {
            body = (root spawn ReadHeartbeat()).reports as any;
        }
        out = Res(ok=True, ms=int(Date.now() - started), body=body);
    } except Exception as e {
        out = Res(ok=False, ms=int(Date.now() - started), body={"error": str(e)});
    }
    busy = False;
}
