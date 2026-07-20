"""WebSockets: pub echo, pub broadcast, and an auth-required socket.

Bodies in `features/impl/websocket.impl.jac`. These are the only async
abilities in the bench, so they pin that an impl annex preserves `async`."""

@restspec(protocol=APIProtocol.WEBSOCKET)
async walker:pub WsEcho {
    has message: str;
    has client_id: str = "anonymous";

    async can go with Root entry;
}

@restspec(protocol=APIProtocol.WEBSOCKET, broadcast=True)
async walker:pub WsBroadcast {
    has message: str;
    has sender: str = "anonymous";

    async can go with Root entry;
}

@restspec(protocol=APIProtocol.WEBSOCKET)
async walker WsPrivate {
    has message: str = "";

    async can go with Root entry;
}
