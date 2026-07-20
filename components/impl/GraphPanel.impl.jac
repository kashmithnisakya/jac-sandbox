"""Handlers for `components/GraphPanel.cl.jac`.

ShareNote's reported id is captured into `docId` so the cross-user read can be
tried immediately — log in as a second user and ReadShared should still resolve
it, which is the whole point of the grant."""

impl GraphPanel.run(probe: str) -> None {
    busy = True;
    started = Date.now();
    try {
        body: any = None;
        if probe == "add_note" {
            body = (root spawn AddNote(text=note)).reports;
        } elif probe == "count_notes" {
            body = (root spawn CountNotes()).reports;
        } elif probe == "share" {
            result = root spawn ShareNote(text=docText);
            reports = result.reports;
            if reports {
                docId = reports[0]["id"];
            }
            body = reports;
        } elif probe == "read_shared" {
            body = (root spawn ReadShared(doc_id=docId)).reports;
        }
        out = Res(ok=True, ms=int(Date.now() - started), body=body);
    } except Exception as e {
        out = Res(ok=False, ms=int(Date.now() - started), body={"error": str(e)});
    }
    busy = False;
}
