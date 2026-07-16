"""Key-value store: scale persistence lib over redis. The client is created
lazily inside the ability so the server boots without redis; the endpoints
fail only when actually called with no backend configured."""

import from jaclang.scale.persistence.lib { kvstore }

walker:pub KvPut {
    has key: str,
        value: str;

    can go with Root entry {
        db = kvstore(db_name="sandbox", db_type="redis");
        db.set(self.key, {"value": self.value});
        report {"stored": self.key};
    }
}

walker:pub KvGet {
    has key: str;

    can go with Root entry {
        db = kvstore(db_name="sandbox", db_type="redis");
        found = db.get(self.key);
        report {"key": self.key, "value": found};
    }
}
