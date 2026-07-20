"""Handlers for `components/UploadPanel.cl.jac`.

Content-Type is left unset on purpose: the browser has to fill it in itself so
the multipart boundary matches the body it generated. Setting it by hand here
is the classic way to turn a working upload into a 422."""

impl UploadPanel.run(target: str) -> None {
    if picked is None {
        out = Res(ok=False, ms=0, body={"error": "pick a file first"});
        return;
    }
    busy = True;
    started = Date.now();
    try {
        form: any = new(FormData);
        if target == "UploadDoc" {
            form.append("document", picked);
            form.append("notes", notes);
        } else {
            form.append("attachment", picked);
        }

        headers = {};
        token = localStorage.getItem("jac_token");
        if token {
            headers["Authorization"] = f"Bearer {token}";
        }

        resp = await fetch(
            f"/walker/{target}", {"method": "POST", "headers": headers, "body": form}
        );
        out = Res(ok=resp.ok, ms=int(Date.now() - started), body=await resp.json());
    } except Exception as e {
        out = Res(ok=False, ms=int(Date.now() - started), body={"error": str(e)});
    }
    busy = False;
}
