"""Handlers for `components/RealtimePanel.cl.jac`."""

"""Read the whole stream and show the frames verbatim.

Deliberately not an incremental reader: SseTicker emits three ticks and ends,
and the thing worth looking at is the frame *format* (`data:` lines then
`event: end`), which `.text()` shows exactly as it came off the wire."""
impl RealtimePanel.runSse -> None {
    busy = True;
    started = Date.now();
    try {
        resp = await fetch(
            "/walker/SseTicker",
            {
                "method": "POST",
                "headers": {"Content-Type": "application/json"},
                "body": JSON.stringify({"count": int(count or "0")})
            }
        );
        raw = await resp.text();
        sseOut = Res(
            ok=resp.ok,
            ms=int(Date.now() - started),
            body={
                "content_type": resp.headers.get("content-type"),
                "frames": [
                    line
                    for line in raw.split("\n")
                    if line.strip()
                ]
            }
        );
    } except Exception as e {
        sseOut = Res(ok=False, ms=int(Date.now() - started), body={"error": str(e)});
    }
    busy = False;
}

"""One socket per click: connect, send one frame, render the reply, close.

Timing is measured across the whole socket lifetime — open, send, first frame —
so it is not comparable to the REST probes' single round trip.

The token rides as `?token=` because a browser cannot set headers on a
WebSocket handshake — that is why WsPrivate is query-authed while every other
auth-gated walker here is Bearer-authed."""
impl RealtimePanel.runWs(target: str) -> None {
    started = Date.now();
    wsOut = None;
    scheme = "wss" if location.protocol == "https:" else "ws";
    url = f"{scheme}://{location.host}/ws/{target}";
    if target == "WsPrivate" {
        token = localStorage.getItem("jac_token");
        if token {
            url = f"{url}?token={token}";
        }
    }

    fields = {"message": wsMsg};
    if target == "WsEcho" {
        fields["client_id"] = "gui";
    } elif target == "WsBroadcast" {
        fields["sender"] = "gui";
    }

    try {
        sock: any = new(WebSocket, url);
        sock.onopen = lambda (ev: any) { sock.send(JSON.stringify(fields)); };
        sock.onmessage = lambda (ev: any) {
            wsOut = Res(
                ok=True, ms=int(Date.now() - started), body=JSON.parse(ev.data)
            );
            sock.close(1000);
        };
        sock.onerror = lambda (ev: any) { wsOut = Res(
            ok=False,
            ms=int(Date.now() - started),
            body={
                "error": f"socket error on /ws/{target}",
                "hint": "WsPrivate rejects the handshake without a valid ?token"
            }
        ); };
    } except Exception as e {
        wsOut = Res(ok=False, ms=int(Date.now() - started), body={"error": str(e)});
    }
}
