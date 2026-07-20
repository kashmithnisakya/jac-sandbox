"""Bodies for `features/restspec_routes.sv.jac`.

The @restspec decorator stays on the decl; only the ability body moves here."""

impl ApiStatus.go with Root entry {
    report {"status": "up", "via": "restspec-get"};
}

impl ApiEcho.go with Root entry {
    report {"echo": self.payload, "via": "restspec-post"};
}
