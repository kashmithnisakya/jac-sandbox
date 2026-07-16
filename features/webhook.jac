"""Webhooks: HMAC-signed endpoints under /webhook/, with and without fields."""

@restspec(protocol=APIProtocol.WEBHOOK)
walker HookOrderPaid {
    has order_id: str,
        amount: float,
        currency: str = "USD";

    can go with Root entry {
        report {
            "status": "received",
            "order_id": self.order_id,
            "amount": self.amount,
            "currency": self.currency
        };
    }
}

@restspec(protocol=APIProtocol.WEBHOOK)
walker HookPing {
    can go with Root entry {
        report {"status": "received", "transport": "webhook"};
    }
}
