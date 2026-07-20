"""Bodies for `features/rest_basic.sv.jac`.

Shared-folder impl annex: `impl/<module>.impl.jac` resolves against a
`<module>.sv.jac` head because no bare `<module>.jac` exists."""

impl PingPub.go with Root entry {
    report {"pong": True, "auth_required": False};
}

impl PingAuth.go with Root entry {
    report {"pong": True, "auth_required": True};
}

impl AddItem.go with Root entry {
    created = here ++> Item(label=self.label);
    report created;
}

impl ListItems.go with Root entry {
    report [-->[?:Item]];
}

impl VisitItem.go with Item entry {
    report {"visited": here.label};
}

impl sandbox_health -> dict {
    return {"ok": True, "service": "jac-sandbox"};
}

impl add_two(a: int, b: int) -> int {
    return a + b;
}
