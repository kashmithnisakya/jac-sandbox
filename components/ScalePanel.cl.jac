"""Scale panel: events, kvstore, and the scheduler.

The three features that lean on infrastructure rather than the request itself.
Two of them are expected to be *visibly* unhappy in a bare local run, and that
is worth showing rather than hiding:

- kvstore wants redis; with none configured it returns an EXECUTION_ERROR
  envelope, which the panel renders as-is.
- the heartbeat only advances if the static @schedule task is actually firing.

Webhooks are absent on purpose: `/webhook/*` requires an X-API-Key plus an
HMAC-SHA256 signature over the body, and signing in the browser would mean
shipping the secret to it. That surface stays in `tests/test_webhook.py`."""

sv import from features.events { EmitEvent, read_events }
sv import from features.kvstore { KvPut, KvGet }
sv import from features.scheduler { ReadHeartbeat }

import from .Bench { Panel, Row, TextInput, RunButton, ResultView, Res, statusOf }

def:pub ScalePanel -> JsxElement {
    has payload: str = "hello",
        key: str = "greeting",
        value: str = "hi there",
        out: any = None,
        busy: bool = False;

    async def run(probe: str) -> None;

    return
        <Panel
            title="Events + kvstore + scheduler"
            blurb="publish/@subscribe delivery, redis-backed kvstore (errors loudly without redis), and the static @schedule heartbeat."
            wire="POST /walker/EmitEvent | /function/read_events | /walker/KvPut | /walker/KvGet | /walker/ReadHeartbeat"
            status={statusOf(out)}
        >
            <Row>
                <TextInput
                    value={payload}
                    onChange={lambda (e: any) { payload = e.target.value; }}
                    placeholder="event payload"
                />
                <RunButton
                    label="EmitEvent"
                    onClick={lambda { run("emit"); }}
                    busy={busy}
                />
                <RunButton
                    label="read_events()"
                    onClick={lambda { run("read_events"); }}
                    busy={busy}
                />
            </Row>
            <Row>
                <TextInput
                    value={key}
                    onChange={lambda (e: any) { key = e.target.value; }}
                    placeholder="key"
                    width="7rem"
                />
                <TextInput
                    value={value}
                    onChange={lambda (e: any) { value = e.target.value; }}
                    placeholder="value"
                />
                <RunButton
                    label="KvPut"
                    onClick={lambda { run("kv_put"); }}
                    busy={busy}
                />
                <RunButton
                    label="KvGet"
                    onClick={lambda { run("kv_get"); }}
                    busy={busy}
                />
            </Row>
            <Row>
                <RunButton
                    label="ReadHeartbeat"
                    onClick={lambda { run("heartbeat"); }}
                    busy={busy}
                />
                <span style={{"color": "#5b6472", "fontSize": "0.8rem"}}>
                    {"beats climb ~1/s while the server runs"}
                </span>
            </Row>
            <ResultView value={out}/>
        </Panel>;
}
