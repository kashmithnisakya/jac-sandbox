"""Handlers for `components/AuthBar.cl.jac`.

Register does not auto-login: the bench wants the two steps separable, so a
401 can be reproduced deliberately."""

impl AuthBar.doRegister -> None {
    busy = True;
    try {
        await jacSignup(username, password);
        note = f"registered {username} — now log in";
    } except Exception as e {
        note = f"register failed: {e}";
    }
    busy = False;
}

impl AuthBar.doLogin -> None {
    busy = True;
    try {
        ok = await jacLogin(username, password);
        note = "logged in" if ok else "login rejected";
    } except Exception as e {
        note = f"login failed: {e}";
    }
    busy = False;
    onAuthChange();
}

impl AuthBar.doLogout -> None {
    jacLogout();
    note = "logged out";
    onAuthChange();
}
