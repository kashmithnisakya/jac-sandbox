"""Bodies for `features/kvstore.sv.jac`."""

impl KvPut.go with Root entry {
    db = kvstore(db_name="sandbox", db_type="redis");
    db.set(self.key, {"value": self.value});
    report {"stored": self.key};
}

impl KvGet.go with Root entry {
    db = kvstore(db_name="sandbox", db_type="redis");
    found = db.get(self.key);
    report {"key": self.key, "value": found};
}
