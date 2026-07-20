"""Bodies for `features/permissions.sv.jac`."""

impl ShareNote.go with Root entry {
    created = here ++> SharedDoc(content=self.text);
    grant(created, level=ReadPerm);
    report {"id": jid(created)};
}

impl ReadShared.go with Root entry {
    doc = jobj(self.doc_id);
    if isinstance(doc, SharedDoc) {
        report {"content": doc.content};
    } else {
        report {"content": None};
    }
}
