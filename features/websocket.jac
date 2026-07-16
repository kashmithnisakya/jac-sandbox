"""WebSockets: pub echo, pub broadcast, and an auth-required socket."""

@restspec(protocol=APIProtocol.WEBSOCKET)
async walker:pub WsEcho {
    has message: str;
    has client_id: str = "anonymous";

    async can go with Root entry {
        report {
            "echo": self.message,
            "client_id": self.client_id,
            "protocol": "websocket"
        };
    }
}

@restspec(protocol=APIProtocol.WEBSOCKET, broadcast=True)
async walker:pub WsBroadcast {
    has message: str;
    has sender: str = "anonymous";

    async can go with Root entry {
        report {
            "type": "message",
            "sender": self.sender,
            "content": self.message,
            "broadcast": True
        };
    }
}

@restspec(protocol=APIProtocol.WEBSOCKET)
async walker WsPrivate {
    has message: str = "";

    async can go with Root entry {
        report {"message": self.message, "authenticated": True};
    }
}
