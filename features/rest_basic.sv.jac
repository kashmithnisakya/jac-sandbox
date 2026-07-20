"""REST basics: pub vs auth walkers, graph writes, node-addressed spawn,
reports vs return values, and plain function endpoints.

Declarations only; bodies live in `features/impl/rest_basic.impl.jac`
(shared-folder impl annex form)."""

node Item {
    has label: str;
}

walker:pub PingPub {
    can go with Root entry;
}

walker PingAuth {
    can go with Root entry;
}

walker AddItem {
    has label: str;

    can go with Root entry;
}

walker ListItems {
    can go with Root entry;
}

walker VisitItem {
    can go with Item entry;
}

def:pub sandbox_health -> dict;

def add_two(a: int, b: int) -> int;
