"""Bodies for `features/events.sv.jac`."""

impl on_sandbox_ping(ev: Event) {
    received_events.append(ev.data);
}

impl EmitEvent.go with Root entry {
    publish(
        "sandbox.ping", Event(event_type="sandbox.ping", data={"msg": self.payload})
    );
    report {"published": True};
}

impl read_events -> dict {
    return {"received": list(received_events)};
}
