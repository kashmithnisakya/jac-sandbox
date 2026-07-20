"""Webhooks: HMAC-signed endpoints under /webhook/, with and without fields.

Bodies in `features/impl/webhook.impl.jac`."""

@restspec(protocol=APIProtocol.WEBHOOK)
walker HookOrderPaid {
    has order_id: str,
        amount: float,
        currency: str = "USD";

    can go with Root entry;
}

@restspec(protocol=APIProtocol.WEBHOOK)
walker HookPing {
    can go with Root entry;
}
