"""Events: publish to a topic; a @subscribe handler records deliveries;
a pub function exposes what arrived so tests can assert delivery."""

import from jaclang.scale.events.broker { Event }
import from jaclang.scale.events.publisher { publish }
import from jaclang.scale.events.subscriber { subscribe }

glob received_events: list = [];

@subscribe("sandbox.ping")
def on_sandbox_ping(ev: Event) {
    received_events.append(ev.data);
}

walker:pub EmitEvent {
    has payload: str = "hello";

    can go with Root entry {
        publish(
            "sandbox.ping",
            Event(event_type="sandbox.ping", data={"msg": self.payload})
        );
        report {"published": True};
    }
}

def:pub read_events -> dict {
    return {"received": list(received_events)};
}
