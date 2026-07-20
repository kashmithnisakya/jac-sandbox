"""Graph persistence: nodes survive across requests; authenticated users
get isolated per-user roots (user A must not see user B's notes).

Bodies in `features/impl/persistence.impl.jac`."""

node Note {
    has text: str;
}

walker AddNote {
    has text: str;

    can go with Root entry;
}

walker CountNotes {
    can go with Root entry;
}
