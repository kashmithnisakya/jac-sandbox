"""Cross-user access: grant read permission on a node, then read it from
another user's context by id.

Bodies in `features/impl/permissions.impl.jac`."""

node SharedDoc {
    has content: str;
}

walker ShareNote {
    has text: str;

    can go with Root entry;
}

walker ReadShared {
    has doc_id: str;

    can go with Root entry;
}
