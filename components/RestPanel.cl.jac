"""REST panel: pub vs auth walkers, graph writes, node-addressed spawn,
function endpoints, and @restspec custom routes.

`PingAuth` and `add_two` are the auth half of the matrix — with no token they
should 401, and that 401 is a result worth seeing, not an error to hide."""

sv import from features.rest_basic {
    PingPub,
    PingAuth,
    AddItem,
    ListItems,
    VisitItem,
    sandbox_health,
    add_two
}

# No `sv import` of ApiStatus/ApiEcho: they are @restspec-routed, and the
# generated client cannot call them (it would POST /walker/<Name> and get a
# 405). The panel fetches their real routes instead.
import from "@jac/runtime" { jacSpawn }

import from .Bench { Panel, Row, TextInput, RunButton, ResultView, Res, statusOf }

def:pub RestPanel(authed: bool) -> JsxElement {
    has label: str = "widget",
        nodeId: str = "",
        echo: str = "hello",
        a: str = "2",
        b: str = "3",
        out: any = None,
        busy: bool = False;

    async def run(probe: str) -> None;

    return
        <Panel
            title="REST basics + custom routes"
            blurb="Pub vs auth walkers, graph writes, node-addressed spawn, function endpoints, @restspec method/path overrides."
            wire="POST /walker/PingPub | /walker/AddItem | /function/sandbox_health | GET /api/v1/status"
            status={statusOf(out)}
        >
            <Row>
                <RunButton
                    label="PingPub (open)"
                    onClick={lambda { run("ping_pub"); }}
                    busy={busy}
                />
                <RunButton
                    label={"PingAuth" if authed else "PingAuth (expect 401)"}
                    onClick={lambda { run("ping_auth"); }}
                    busy={busy}
                />
                <RunButton
                    label="sandbox_health()"
                    onClick={lambda { run("health"); }}
                    busy={busy}
                />
            </Row>
            <Row>
                <TextInput
                    value={a}
                    onChange={lambda (e: any) { a = e.target.value; }}
                    width="4rem"
                />
                <TextInput
                    value={b}
                    onChange={lambda (e: any) { b = e.target.value; }}
                    width="4rem"
                />
                <RunButton
                    label={"add_two()" if authed else "add_two() (expect 401)"}
                    onClick={lambda { run("add_two"); }}
                    busy={busy}
                />
            </Row>
            <Row>
                <TextInput
                    value={label}
                    onChange={lambda (e: any) { label = e.target.value; }}
                    placeholder="item label"
                />
                <RunButton
                    label="AddItem"
                    onClick={lambda { run("add_item"); }}
                    busy={busy}
                />
                <RunButton
                    label="ListItems"
                    onClick={lambda { run("list_items"); }}
                    busy={busy}
                />
            </Row>
            <Row>
                <TextInput
                    value={nodeId}
                    onChange={lambda (e: any) { nodeId = e.target.value; }}
                    placeholder="node id from AddItem"
                    width="20rem"
                />
                <RunButton
                    label="VisitItem (by id)"
                    onClick={lambda { run("visit_item"); }}
                    busy={busy}
                />
            </Row>
            <Row>
                <RunButton
                    label="GET /api/v1/status"
                    onClick={lambda { run("api_status"); }}
                    busy={busy}
                />
                <TextInput
                    value={echo}
                    onChange={lambda (e: any) { echo = e.target.value; }}
                    placeholder="payload"
                />
                <RunButton
                    label="POST /api/v1/echo"
                    onClick={lambda { run("api_echo"); }}
                    busy={busy}
                />
            </Row>
            <ResultView value={out}/>
        </Panel>;
}
