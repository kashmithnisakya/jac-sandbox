"""Cross-user access: grant read permission on a node, then read it from
another user's context by id."""

node SharedDoc {
    has content: str;
}

walker ShareNote {
    has text: str;

    can go with Root entry {
        created = here ++> SharedDoc(content=self.text);
        grant(created, level=ReadPerm);
        report {"id": jid(created)};
    }
}

walker ReadShared {
    has doc_id: str;

    can go with Root entry {
        doc = jobj(self.doc_id);
        if isinstance(doc, SharedDoc) {
            report {"content": doc.content};
        } else {
            report {"content": None};
        }
    }
}
