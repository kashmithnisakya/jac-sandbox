"""Upload panel: multipart UploadFile fields.

`root spawn` cannot carry a file. The generated client always sends
`JSON.stringify(fields)` with `Content-Type: application/json`, so a walker
with an `UploadFile` field is only reachable over hand-built multipart — which
is exactly why this panel exists. If a conversion ever teaches the typed client
to speak multipart, this is the panel that should get simpler.

`FormData` is used bare. Like `WebSocket`, it had no stub in Jac's client type
system until this bench found the gap (jac #7522) — see
`components/RealtimePanel.cl.jac` for the full story."""

import from .Bench { Panel, Row, TextInput, RunButton, ResultView, Res, statusOf }

def:pub UploadPanel(authed: bool) -> JsxElement {
    has picked: any = None,
        notes: str = "from the bench",
        out: any = None,
        busy: bool = False;

    async def run(target: str) -> None;

    return
        <Panel
            title="File uploads"
            blurb="Multipart UploadFile fields, auth and pub variants. The server reports filename, content type and size back."
            wire="POST /walker/UploadDoc (auth) | /walker/UploadPublic (open)"
            status={statusOf(out)}
        >
            <Row>
                <input
                    type="file"
                    onChange={lambda (e: any) { picked = e.target.files[0]; }}
                    style={{"fontSize": "0.82rem"}}
                />
                <TextInput
                    value={notes}
                    onChange={lambda (e: any) { notes = e.target.value; }}
                    placeholder="notes"
                />
            </Row>
            <Row>
                <RunButton
                    label={"UploadDoc" if authed else "UploadDoc (expect 401)"}
                    onClick={lambda { run("UploadDoc"); }}
                    busy={busy}
                />
                <RunButton
                    label="UploadPublic (open)"
                    onClick={lambda { run("UploadPublic"); }}
                    busy={busy}
                />
                <span style={{"color": "#5b6472", "fontSize": "0.8rem"}}>
                    {picked.name if picked else "no file picked"}
                </span>
            </Row>
            <ResultView value={out}/>
        </Panel>;
}
