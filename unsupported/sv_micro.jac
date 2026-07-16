"""Microservice split (sv import): deliberately NOT imported by main.jac.
This module exists so the converter's capability audit has a loud-failure
test case; converting a project that includes it must fail with a clear
message, never silently demote."""

sv import from features.rest_basic { PingPub }

walker:pub MicroPing {
    can go with Root entry {
        report {"pong": True, "via": "microservice"};
    }
}
