"""Graph panel: persistence, per-user isolation, and cross-user permissions.

Both features here are auth-only by design — isolation and `grant` are
meaningless without a user, so the panel says so rather than 401-ing."""

sv import from features.persistence { AddNote, CountNotes }
sv import from features.permissions { ShareNote, ReadShared }

import from .Bench { Panel, Row, TextInput, RunButton, ResultView, Res, Hint, statusOf }

def:pub GraphPanel(authed: bool) -> JsxElement {
    has note: str = "first note",
        docText: str = "shared doc",
        docId: str = "",
        out: any = None,
        busy: bool = False;

    async def run(probe: str) -> None;

    return
        <Panel
            title="Persistence + permissions"
            blurb="Notes persist on your own root and stay invisible to other users. ShareNote grants ReadPerm so another user can read the node by id."
            wire="POST /walker/AddNote | /walker/CountNotes | /walker/ShareNote | /walker/ReadShared"
            status={statusOf(out)}
            gated
        >
            {<Hint text="Log in first — every walker here is auth-only." tone="warn"/>
                if not authed
                else None}
            <Row>
                <TextInput
                    value={note}
                    onChange={lambda (e: any) { note = e.target.value; }}
                    placeholder="note text"
                />
                <RunButton
                    label="AddNote"
                    onClick={lambda { run("add_note"); }}
                    busy={busy}
                />
                <RunButton
                    label="CountNotes"
                    onClick={lambda { run("count_notes"); }}
                    busy={busy}
                />
            </Row>
            <Row>
                <TextInput
                    value={docText}
                    onChange={lambda (e: any) { docText = e.target.value; }}
                    placeholder="doc content"
                />
                <RunButton
                    label="ShareNote"
                    onClick={lambda { run("share"); }}
                    busy={busy}
                />
            </Row>
            <Row>
                <TextInput
                    value={docId}
                    onChange={lambda (e: any) { docId = e.target.value; }}
                    placeholder="doc id from ShareNote"
                    width="20rem"
                />
                <RunButton
                    label="ReadShared"
                    onClick={lambda { run("read_shared"); }}
                    busy={busy}
                />
            </Row>
            <ResultView value={out}/>
        </Panel>;
}
