"""Custom REST routes via @restspec: method + path overrides."""

import from jaclang.scale.jserver.jserver { HTTPMethod }

@restspec(method=HTTPMethod.GET, path="/api/v1/status")
walker:pub ApiStatus {
    can go with Root entry {
        report {"status": "up", "via": "restspec-get"};
    }
}

@restspec(method=HTTPMethod.POST, path="/api/v1/echo")
walker:pub ApiEcho {
    has payload: str = "";

    can go with Root entry {
        report {"echo": self.payload, "via": "restspec-post"};
    }
}
