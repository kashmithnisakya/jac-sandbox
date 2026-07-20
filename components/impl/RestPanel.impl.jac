"""Handlers for `components/RestPanel.cl.jac`.

One dispatch rather than one handler per probe: the panel has nine buttons and
they differ only in which call they make, so a switch keeps the shape visible
and the timing/error wrapping lives in exactly one place.

A 401 does not raise here. The generated client swallows it: on 401 it drops
the stored token and hands back a bare `{}`, so an auth probe run while logged
out returns an object with no `reports` and quietly signs you out. `_reports`
turns that into a legible result instead of an `undefined` in the output box."""

"""Unwrap a spawn result, naming the empty-object shape the client returns on 401."""
def _reports(result: any) -> any {
    if not result or result.reports is None {
        return {
            "note": "401 — no reports came back, and the client just cleared the token",
            "hint": "log in again, then retry"
        };
    }
    return result.reports;
}

impl RestPanel.run(probe: str) -> None {
    busy = True;
    started = Date.now();
    try {
        body: any = None;
        if probe == "ping_pub" {
            body = _reports(root spawn PingPub());
        } elif probe == "ping_auth" {
            body = _reports(root spawn PingAuth());
        } elif probe == "health" {
            body = await sandbox_health();
        } elif probe == "add_two" {
            body = {"sum": await add_two(int(a or "0"), int(b or "0"))};
        } elif probe == "add_item" {
            result = root spawn AddItem(label=label);
            reports = result.reports if result else None;
            if reports {
                nodeId = jid(reports[0]);
            }
            body = _reports(result);
        } elif probe == "list_items" {
            body = _reports(root spawn ListItems());
        } elif probe == "visit_item" {
            if not nodeId {
                raise ValueError("run AddItem first — it fills in the node id");
            }
            # `nodeId spawn VisitItem()` will not typecheck: the spawn sugar
            # wants a live node and all the browser has is an id string.
            # jacSpawn is the addressed form -> POST /walker/VisitItem/{id}.
            body = _reports(await jacSpawn("VisitItem", nodeId, {}));
        } elif probe == "api_status" {
            # Fetched, not spawned. `root spawn ApiStatus()` POSTs to
            # /walker/ApiStatus and gets 405: the generated client ignores
            # @restspec's method/path, so a custom-routed walker is only
            # reachable at its real route. See FEATURES.md C1.
            resp = await fetch("/api/v1/status");
            body = await resp.json();
        } elif probe == "api_echo" {
            resp = await fetch(
                "/api/v1/echo",
                {
                    "method": "POST",
                    "headers": {"Content-Type": "application/json"},
                    "body": JSON.stringify({"payload": echo})
                }
            );
            body = await resp.json();
        }
        out = Res(ok=True, ms=int(Date.now() - started), body=body);
    } except Exception as e {
        out = Res(ok=False, ms=int(Date.now() - started), body={"error": str(e)});
    }
    busy = False;
}
