"""REST basics: pub vs auth walkers, graph writes, node-addressed spawn,
reports vs return values, and plain function endpoints."""

node Item {
    has label: str;
}

walker:pub PingPub {
    can go with Root entry {
        report {"pong": True, "auth_required": False};
    }
}

walker PingAuth {
    can go with Root entry {
        report {"pong": True, "auth_required": True};
    }
}

walker AddItem {
    has label: str;

    can go with Root entry {
        created = here ++> Item(label=self.label);
        report created;
    }
}

walker ListItems {
    can go with Root entry {
        report [-->[?:Item]];
    }
}

walker VisitItem {
    can go with Item entry {
        report {"visited": here.label};
    }
}

def:pub sandbox_health -> dict {
    return {"ok": True, "service": "jac-sandbox"};
}

def add_two(a: int, b: int) -> int {
    return a + b;
}
