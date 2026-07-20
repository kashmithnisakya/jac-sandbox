"""Bodies for `frontend.cl.jac`.

The shell owns exactly one piece of state — whether a token is present — so
the auth-gated panels can say so up front instead of every probe discovering
its own 401 separately."""

impl app.syncAuth -> None {
    authed = jacIsLoggedIn();
}
