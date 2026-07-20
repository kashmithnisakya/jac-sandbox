"""Events: publish to a topic; a @subscribe handler records deliveries;
a pub function exposes what arrived so tests can assert delivery.

Bodies in `features/impl/events.impl.jac`. The @subscribe decorator stays
on the decl so the carrier registers from the entry import closure."""

import from jaclang.scale.events.broker { Event }
import from jaclang.scale.events.publisher { publish }
import from jaclang.scale.events.subscriber { subscribe }

glob received_events: list = [];

@subscribe("sandbox.ping")
def on_sandbox_ping(ev: Event);

walker:pub EmitEvent {
    has payload: str = "hello";

    can go with Root entry;
}

def:pub read_events -> dict;
