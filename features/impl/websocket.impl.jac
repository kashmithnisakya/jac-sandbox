"""Bodies for `features/websocket.sv.jac`."""

impl WsEcho.go with Root entry {
    report {"echo": self.message, "client_id": self.client_id, "protocol": "websocket"};
}

impl WsBroadcast.go with Root entry {
    report {
        "type": "message",
        "sender": self.sender,
        "content": self.message,
        "broadcast": True
    };
}

impl WsPrivate.go with Root entry {
    report {"message": self.message, "authenticated": True};
}
