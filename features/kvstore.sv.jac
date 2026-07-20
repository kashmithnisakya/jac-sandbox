"""Key-value store: scale persistence lib over redis. The client is created
lazily inside the ability so the server boots without redis; the endpoints
fail only when actually called with no backend configured.

Bodies in `features/impl/kvstore.impl.jac` — the lazy `kvstore(...)` call
must stay inside the ability body, not hoist to a glob."""

import from jaclang.scale.persistence.lib { kvstore }

walker:pub KvPut {
    has key: str,
        value: str;

    can go with Root entry;
}

walker:pub KvGet {
    has key: str;

    can go with Root entry;
}
