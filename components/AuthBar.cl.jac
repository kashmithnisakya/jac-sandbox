"""Auth bar: register / login / logout, pinned to the top of the page.

Roughly half the bench is auth-gated (`walker` without `:pub`), so without a
token those panels only ever show 401s. This is the switch that makes the
difference between the two halves of the matrix visible — and it is sticky
because you need to flip it while looking at a panel further down."""

import from "@jac/runtime" { jacLogin, jacSignup, jacLogout, jacIsLoggedIn }

import from .Bench { Row, TextInput, RunButton, Tag, PALETTE }

def:pub AuthBar(authed: bool, onAuthChange: Callable[[], None]) -> JsxElement {
    has username: str = "bench-user",
        password: str = "bench-pw-1",
        note: str = "",
        busy: bool = False;

    async def doRegister -> None;
    async def doLogin -> None;
    def doLogout -> None;

    return
        <div
            style={{
                "position": "sticky",
                "top": "0",
                "zIndex": "10",
                "border": f"1px solid {PALETTE['line']}",
                "backgroundColor": "rgba(255,255,255,0.92)",
                "backdropFilter": "blur(6px)",
                "borderRadius": "12px",
                "padding": "0.7rem 1.1rem",
                "marginBottom": "1rem",
                "boxShadow": "0 1px 2px rgba(16,24,40,0.04)"
            }}
        >
            <Row>
                <Tag
                    text={"signed in" if authed else "anonymous"}
                    tone={"ok" if authed else "muted"}
                />
                <span
                    style={{
                        "color": PALETTE["muted"],
                        "fontSize": "0.8rem",
                        "flex": "1"
                    }}
                >
                    {"auth-gated panels will answer"
                        if authed
                        else "auth-gated panels will 401 until you log in"}
                </span>
            </Row>
            <Row>
                <TextInput
                    value={username}
                    onChange={lambda (e: any) { username = e.target.value; }}
                    placeholder="username"
                />
                <TextInput
                    value={password}
                    onChange={lambda (e: any) { password = e.target.value; }}
                    placeholder="password"
                />
                <RunButton
                    label="Register"
                    onClick={doRegister}
                    busy={busy}
                    tone="ghost"
                />
                <RunButton label="Log in" onClick={doLogin} busy={busy}/>
                <RunButton label="Log out" onClick={doLogout} tone="ghost"/>
            </Row>
            {<span style={{"fontSize": "0.78rem", "color": PALETTE["muted"]}}>
                {note}
            </span>
                if note
                else None}
        </div>;
}
