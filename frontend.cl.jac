"""jac-sandbox - Client-Side UI: the GUI test bench.

One panel per feature row in FEATURES.md, so every endpoint the server exposes
can be driven by hand from a browser and its raw envelope read back. This is
the human-facing twin of `tests/` — the pytest suite asserts the wire contract,
this page lets you go and look at it.

Panels call the server the idiomatic way (`sv import` + `root spawn` / direct
function call), which is the point: that call path is itself part of what the
conversion has to reproduce, so exercising it here exercises the converter.

Bodies in `impl/frontend.impl.jac`."""

import from "@jac/runtime" { jacIsLoggedIn }

import from .components.AuthBar { AuthBar }
import from .components.RestPanel { RestPanel }
import from .components.GraphPanel { GraphPanel }
import from .components.RealtimePanel { RealtimePanel }
import from .components.ScalePanel { ScalePanel }
import from .components.UploadPanel { UploadPanel }
import from .components.AiPanel { AiPanel }
import from .components.NativePanel { NativePanel }
import from .components.GuestbookPanel { GuestbookPanel }

def:pub app -> JsxElement {
    has authed: bool = False;

    can with entry {
        syncAuth();
    }

    def syncAuth -> None;

    return
        <div
            style={{
                "maxWidth": "900px",
                "margin": "0 auto",
                "padding": "1.5rem 1rem 4rem",
                "fontFamily": "system-ui, -apple-system, 'Segoe UI', sans-serif",
                "color": "#101828",
                "backgroundColor": "#f9fafb",
                "minHeight": "100vh"
            }}
        >
            <header style={{"marginBottom": "1.1rem"}}>
                <h1
                    style={{
                        "margin": "0 0 0.2rem",
                        "fontSize": "1.45rem",
                        "letterSpacing": "-0.01em"
                    }}
                >
                    jac-sandbox
                </h1>
                <p
                    style={{
                        "color": "#667085",
                        "margin": "0",
                        "fontSize": "0.88rem",
                        "lineHeight": "1.5"
                    }}
                >
                    Feature-matrix test bench. Every endpoint is wired to the running server — click a probe and read the envelope. Headers collapse; the dot is the last verdict.
                </p>
            </header>
            <AuthBar authed={authed} onAuthChange={syncAuth}/>
            <RestPanel authed={authed}/>
            <GraphPanel authed={authed}/>
            <NativePanel/>
            <RealtimePanel authed={authed}/>
            <ScalePanel/>
            <UploadPanel authed={authed}/>
            <AiPanel/>
            <GuestbookPanel/>
        </div>;
}
