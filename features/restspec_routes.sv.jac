"""Custom REST routes via @restspec: method + path overrides.

Bodies in `features/impl/restspec_routes.impl.jac`."""

import from jaclang.scale.jserver.jserver { HTTPMethod }

@restspec(method=HTTPMethod.GET, path="/api/v1/status")
walker:pub ApiStatus {
    can go with Root entry;
}

@restspec(method=HTTPMethod.POST, path="/api/v1/echo")
walker:pub ApiEcho {
    has payload: str = "";

    can go with Root entry;
}
