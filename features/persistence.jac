"""Graph persistence: nodes survive across requests; authenticated users
get isolated per-user roots (user A must not see user B's notes)."""

node Note {
    has text: str;
}

walker AddNote {
    has text: str;

    can go with Root entry {
        created = here ++> Note(text=self.text);
        report created;
    }
}

walker CountNotes {
    can go with Root entry {
        report {"count": len([-->[?:Note]])};
    }
}
