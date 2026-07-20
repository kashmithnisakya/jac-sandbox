"""Bodies for `features/webhook.sv.jac`."""

impl HookOrderPaid.go with Root entry {
    report {
        "status": "received",
        "order_id": self.order_id,
        "amount": self.amount,
        "currency": self.currency
    };
}

impl HookPing.go with Root entry {
    report {"status": "received", "transport": "webhook"};
}
