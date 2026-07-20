"""Bodies for `features/persistence.sv.jac`."""

impl AddNote.go with Root entry {
    created = here ++> Note(text=self.text);
    report created;
}

impl CountNotes.go with Root entry {
    report {"count": len([-->[?:Note]])};
}
