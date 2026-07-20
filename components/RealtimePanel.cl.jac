"""Realtime panel: SSE frames and WebSocket round-trips.

The only panel that does not go through `root spawn`. SSE and WebSocket are
transports the typed client call has no shape for — a generator-reporting
walker answers `text/event-stream`, and `/ws/<Walker>` wants a real socket —
so this panel drops to the browser primitives and shows the raw wire.

`WebSocket` is used bare here. It did not type-check until this bench found
that `js_globals.pyi` shipped no stub for it (jac #7522); it does now, so no
workaround is needed. The workaround this file used to carry —
`glob WebSocket: any;` — was itself a trap: it type-checked and then threw
"undefined is not a constructor" at runtime, because an initializer-less
`glob` lowered to a module-scope binding that shadowed the real global. Both
are fixed in the compiler; this file is the regression test. See FEATURES.md."""

import from .Bench { Panel, Row, TextInput, RunButton, ResultView, Res, statusOf }

def:pub RealtimePanel(authed: bool) -> JsxElement {
    has count: str = "3",
        wsMsg: str = "hi-ws",
        sseOut: any = None,
        wsOut: any = None,
        busy: bool = False;

    async def runSse -> None;
    def runWs(target: str) -> None;

    return
        <Panel
            title="Streaming + WebSockets"
            blurb="A generator report becomes SSE frames. /ws/<Walker> takes one JSON message and answers one result frame; WsPrivate needs a ?token."
            wire="POST /walker/SseTicker (text/event-stream) | ws /ws/WsEcho | /ws/WsBroadcast | /ws/WsPrivate"
            status={statusOf(wsOut) if wsOut is not None else statusOf(sseOut)}
        >
            <Row>
                <TextInput
                    value={count}
                    onChange={lambda (e: any) { count = e.target.value; }}
                    placeholder="ticks"
                    width="5rem"
                />
                <RunButton label="SseTicker" onClick={runSse} busy={busy}/>
            </Row>
            <ResultView value={sseOut} label="sse"/>
            <div style={{"height": "0.85rem"}}/>
            <Row>
                <TextInput
                    value={wsMsg}
                    onChange={lambda (e: any) { wsMsg = e.target.value; }}
                    placeholder="message"
                />
                <RunButton label="WsEcho" onClick={lambda { runWs("WsEcho"); }}/>
                <RunButton
                    label="WsBroadcast"
                    onClick={lambda { runWs("WsBroadcast"); }}
                />
                <RunButton
                    label={"WsPrivate" if authed else "WsPrivate (expect reject)"}
                    onClick={lambda { runWs("WsPrivate"); }}
                />
            </Row>
            <ResultView value={wsOut} label="websocket"/>
        </Panel>;
}
