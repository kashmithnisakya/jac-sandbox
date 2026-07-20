"""Shared UI primitives for the test bench.

The page is a probe, not a product: every panel looks the same so the eye goes
to the payload. What the chrome is for is answering three questions without
reading JSON — did it work, how long did it take, and is this endpoint gated.

`Res` is the shape every probe returns. Carrying `ok` and `ms` alongside the
body is what lets a panel show a verdict instead of a wall of text — and `ms`
is not decoration here: it is how you see that `NativeFib` is doing real work
in machine code rather than quietly falling back to a Python reimplementation.
"""

"""`:pub` on both of these is load-bearing, not decoration.

A cl module importing a non-`:pub` symbol from a sibling type-checks perfectly
— `jac check` stays green — and then rollup fails the bundle with
`"X" is not exported by ...`, which `jac start` serves as a bare 503. The
compile-time and bundle-time notions of "exported" disagree. See FEATURES.md."""
obj:pub Res {
    has ok: bool = True,
        ms: int = 0,
        body: any = None;
}

glob:pub PALETTE: dict = {
         "line": "#e4e7ec",
         "muted": "#667085",
         "faint": "#98a2b3",
         "ink": "#101828",
         "code_bg": "#0b1120",
         "code_fg": "#cbd5e1",
         "ok_fg": "#067647",
         "ok_bg": "#ecfdf3",
         "ok_line": "#abefc6",
         "err_fg": "#b42318",
         "err_bg": "#fef3f2",
         "err_line": "#fecdca"
     };

"""A collapsible feature card.

`status` drives the dot: idle / ok / error. It is a prop rather than derived
state because the panel owns the result — the card only reports it.

`children` defaults so the checker treats it as optional: JSX passes children
implicitly, and a required `children` param reads as a missing prop (E1102)."""
def:pub Panel(
    title: str,
    blurb: str,
    wire: str,
    status: str = "idle",
    gated: bool = False,
    children: any = None
) -> JsxElement {
    has open: bool = True;

    dot = PALETTE["faint"];
    if status == "ok" {
        dot = "#17b26a";
    } elif status == "error" {
        dot = "#f04438";
    }

    return
        <section
            style={{
                "border": f"1px solid {PALETTE['line']}",
                "borderRadius": "12px",
                "marginBottom": "0.85rem",
                "backgroundColor": "#fff",
                "boxShadow": "0 1px 2px rgba(16,24,40,0.04)",
                "overflow": "hidden"
            }}
        >
            <header
                onClick={lambda { open = not open; }}
                style={{
                    "display": "flex",
                    "alignItems": "center",
                    "gap": "0.6rem",
                    "padding": "0.85rem 1.1rem",
                    "cursor": "pointer",
                    "userSelect": "none"
                }}
            >
                <span
                    style={{
                        "width": "8px",
                        "height": "8px",
                        "borderRadius": "50%",
                        "backgroundColor": dot,
                        "flexShrink": "0"
                    }}
                />
                <div style={{"flex": "1", "minWidth": "0"}}>
                    <div
                        style={{
                            "display": "flex",
                            "alignItems": "center",
                            "gap": "0.5rem"
                        }}
                    >
                        <h2
                            style={{
                                "margin": "0",
                                "fontSize": "0.98rem",
                                "fontWeight": "600",
                                "color": PALETTE["ink"]
                            }}
                        >
                            {title}
                        </h2>
                        {<Tag text="auth" tone="warn"/> if gated else None}
                    </div>
                    <p
                        style={{
                            "margin": "0.15rem 0 0",
                            "color": PALETTE["muted"],
                            "fontSize": "0.82rem",
                            "lineHeight": "1.4"
                        }}
                    >
                        {blurb}
                    </p>
                </div>
                <span style={{"color": PALETTE["faint"], "fontSize": "0.75rem"}}>
                    {"–" if open else "+"}
                </span>
            </header>
            {<div style={{"padding": "0 1.1rem 1.1rem"}}>
                <code
                    style={{
                        "display": "block",
                        "marginBottom": "0.75rem",
                        "color": PALETTE["faint"],
                        "fontSize": "0.74rem",
                        "wordBreak": "break-word"
                    }}
                >
                    {wire}
                </code>
                {children}
            </div>
                if open
                else None}
        </section>;
}

def:pub Tag(text: str, tone: str = "muted") -> JsxElement {
    fg = PALETTE["muted"];
    bg = "#f2f4f7";
    if tone == "ok" {
        fg = PALETTE["ok_fg"];
        bg = PALETTE["ok_bg"];
    } elif tone == "error" {
        fg = PALETTE["err_fg"];
        bg = PALETTE["err_bg"];
    } elif tone == "warn" {
        fg = "#b54708";
        bg = "#fffaeb";
    }
    return
        <span
            style={{
                "fontSize": "0.68rem",
                "fontWeight": "600",
                "letterSpacing": "0.02em",
                "textTransform": "uppercase",
                "padding": "0.12rem 0.4rem",
                "borderRadius": "5px",
                "color": fg,
                "backgroundColor": bg,
                "whiteSpace": "nowrap"
            }}
        >
            {text}
        </span>;
}

def:pub Row(children: any = None) -> JsxElement {
    return
        <div
            style={{
                "display": "flex",
                "gap": "0.45rem",
                "alignItems": "center",
                "flexWrap": "wrap",
                "marginBottom": "0.5rem"
            }}
        >
            {children}
        </div>;
}

def:pub TextInput(
    value: str,
    onChange: Callable[[any], None],
    placeholder: str = "",
    width: str = "10rem"
) -> JsxElement {
    return
        <input
            type="text"
            value={value}
            onChange={onChange}
            placeholder={placeholder}
            style={{
                "padding": "0.4rem 0.55rem",
                "border": "1px solid #d0d5dd",
                "borderRadius": "7px",
                "fontSize": "0.84rem",
                "color": PALETTE["ink"],
                "width": width,
                "outline": "none"
            }}
        />;
}

def:pub RunButton(
    label: str, onClick: Callable[[], None], busy: bool = False, tone: str = "primary"
) -> JsxElement {
    bg = "#2f6feb";
    fg = "white";
    border = "1px solid #2f6feb";
    if tone == "ghost" {
        bg = "#fff";
        fg = "#344054";
        border = "1px solid #d0d5dd";
    }
    if busy {
        bg = "#98a2b3";
        border = "1px solid #98a2b3";
        fg = "white";
    }
    return
        <button
            onClick={onClick}
            disabled={busy}
            style={{
                "padding": "0.4rem 0.75rem",
                "backgroundColor": bg,
                "color": fg,
                "border": border,
                "borderRadius": "7px",
                "cursor": "wait" if busy else "pointer",
                "fontSize": "0.82rem",
                "fontWeight": "500",
                "whiteSpace": "nowrap"
            }}
        >
            {"…" if busy else label}
        </button>;
}

def:pub Hint(text: str, tone: str = "muted") -> JsxElement {
    color = PALETTE["muted"];
    if tone == "warn" {
        color = "#b54708";
    }
    return
        <p style={{"margin": "0 0 0.5rem", "fontSize": "0.8rem", "color": color}}>
            {text}
        </p>;
}

"""Render a probe's verdict, then its payload.

`None` means the probe has not run — visually distinct from a probe that ran
and returned nothing, which is a real (and interesting) result."""
def:pub ResultView(value: any = None, label: str = "") -> JsxElement {
    if value is None {
        return
            <pre
                style={{
                    "margin": "0",
                    "padding": "0.5rem 0.65rem",
                    "backgroundColor": "#fcfcfd",
                    "border": f"1px dashed {PALETTE['line']}",
                    "borderRadius": "7px",
                    "color": PALETTE["faint"],
                    "fontSize": "0.76rem"
                }}
            >
                {f"{label} not run yet" if label else "not run yet"}
            </pre>;
    }
    return
        <div>
            <div
                style={{
                    "display": "flex",
                    "alignItems": "center",
                    "gap": "0.4rem",
                    "marginBottom": "0.3rem"
                }}
            >
                <Tag
                    text={"ok" if value.ok else "error"}
                    tone={"ok" if value.ok else "error"}
                />
                <span style={{"fontSize": "0.72rem", "color": PALETTE["faint"]}}>
                    {f"{value.ms} ms"}
                </span>
                {<span style={{"fontSize": "0.72rem", "color": PALETTE["faint"]}}>
                    {label}
                </span>
                    if label
                    else None}
            </div>
            <pre
                style={{
                    "margin": "0",
                    "padding": "0.6rem 0.7rem",
                    "backgroundColor": PALETTE["code_bg"],
                    "color": PALETTE["code_fg"],
                    "borderRadius": "7px",
                    "fontSize": "0.76rem",
                    "lineHeight": "1.5",
                    "maxHeight": "18rem",
                    "overflow": "auto",
                    "whiteSpace": "pre-wrap",
                    "wordBreak": "break-word"
                }}
            >
                {JSON.stringify(value.body, None, 2)}
            </pre>
        </div>;
}

"""Status string for a Panel's dot, from a probe result."""
def:pub statusOf(value: any = None) -> str {
    if value is None {
        return "idle";
    }
    return "ok" if value.ok else "error";
}
