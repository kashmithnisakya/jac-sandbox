# Feature Matrix

The conversion burn-down list. A converter feature is done when its row's
conformance tests pass against BOTH `jac start` and the converted output.

## Layout

The bench exercises the three codespaces and the annex system deliberately,
because file shape is itself part of what a converter has to handle:

| Shape | Where | Why it is here |
| --- | --- | --- |
| `*.sv.jac` | `features/`, `endpoints.sv.jac` | Server codespace, stated explicitly rather than inferred from a bare `.jac` |
| `*.cl.jac` | `frontend.cl.jac`, `components/` | Client codespace — compiles to JS, never runs on the server |
| `*.na.jac` | `features/native_compute.na.jac` | Native codespace — LLVM, no Python runtime, inside the E5090 capability boundary |
| `impl/<mod>.impl.jac` | `impl/`, `features/impl/`, `components/impl/` | Every declaration is split from its body via the shared-folder impl annex |

Declarations live in the head file; bodies live in the annex. The annex is
resolved per-directory (`features/foo.sv.jac` -> `features/impl/foo.impl.jac`),
and it resolves against `.sv.jac` / `.cl.jac` / `.na.jac` heads alike — the
`.na.jac` case included, which is the least-travelled path of the three.

What must NOT move to an annex: `@restspec` / `@schedule` / `@subscribe`
decorators, `sem` strings, and `by llm()` bindings. Those are the decl — a
`sem` string is the prompt, and moving it would change the wire.

## Matrix

| Feature | Module | Endpoints / surface | GUI panel | Expected behavior |
| --- | --- | --- | --- | --- |
| Pub vs auth walkers | `features/rest_basic.sv.jac` | `POST /walker/PingPub` (open), `POST /walker/PingAuth` (401 without token) | `RestPanel` | Auth default is compiler-decided (`:pub` = open) |
| Graph writes + typed reads | `features/rest_basic.sv.jac` | `POST /walker/AddItem`, `POST /walker/ListItems` | `RestPanel` | Items created, listed from user root |
| Node-addressed spawn | `features/rest_basic.sv.jac` | `POST /walker/VisitItem/{node_id}` | `RestPanel` | Spawns on an arbitrary node by id |
| Function endpoints | `features/rest_basic.sv.jac` | `POST /function/sandbox_health` (pub), `POST /function/add_two` (auth) | `RestPanel` | Return values, not reports |
| Custom REST routes | `features/restspec_routes.sv.jac` | `GET /api/v1/status`, `POST /api/v1/echo` | `RestPanel` (fetched, not spawned — see C1) | `@restspec(method, path)` overrides |
| SSE streaming | `features/streaming.sv.jac` | `POST /walker/SseTicker` | `RealtimePanel` | Generator report streams as SSE frames |
| File uploads | `features/uploads.sv.jac` | `POST /walker/UploadDoc` (auth), `POST /walker/UploadPublic` (pub) | `UploadPanel` (multipart via fetch — see C2) | Multipart UploadFile fields |
| Persistence + isolation | `features/persistence.sv.jac` | `POST /walker/AddNote`, `POST /walker/CountNotes` | `GraphPanel` | Notes survive restarts; user A cannot see user B's notes |
| Permissions | `features/permissions.sv.jac` | `POST /walker/ShareNote`, `POST /walker/ReadShared` | `GraphPanel` | `grant(ReadPerm)` + cross-user read by node id |
| Scheduled jobs | `features/scheduler.sv.jac` | `@schedule` interval walker + `POST /walker/ReadHeartbeat` | `ScalePanel` | Beats accumulate while server runs |
| WebSockets | `features/websocket.sv.jac` | `ws /ws/WsEcho` (pub), `ws /ws/WsBroadcast` (broadcast), `ws /ws/WsPrivate` (auth) | `RealtimePanel` | Token handshake, result frames, broadcast fan-out |
| Webhooks | `features/webhook.sv.jac` | `POST /webhook/HookOrderPaid`, `POST /webhook/HookPing` | none — see below | HMAC + replay verification via /api-key/create keys |
| Events | `features/events.sv.jac` | `POST /walker/EmitEvent`, `POST /function/read_events` | `ScalePanel` | `publish` -> `@subscribe` handler delivery |
| Key-value store | `features/kvstore.sv.jac` | `POST /walker/KvPut`, `POST /walker/KvGet` | `ScalePanel` | Redis-backed kvstore; lazy client so boot works without redis |
| Typed by llm() | `features/byllm_typed.sv.jac` | `POST /walker/Classify` | `AiPanel` | Structured output via sem strings + MockLLM; prompt-fidelity golden pins MTIR parity |
| by llm() with tools | `features/byllm_tools.sv.jac` | `POST /walker/Advise` | `AiPanel` | ReAct tool loop, scripted MockLLM |
| **Native compute (`na`)** | `features/native_compute.na.jac` | — (no server of its own) | — | LLVM-compiled `fib` / `checksum` / `count_primes`, inside the E5090 boundary |
| **sv -> na bridge** | `features/native.sv.jac` | `POST /walker/NativeFib`, `/walker/NativeChecksum`, `/walker/NativePrimes` | `NativePanel` | Walker calls native code over the generated ctypes trampoline; reports tag `"via": "native"` |
| **impl annex resolution** | `*/impl/*.impl.jac` | every endpoint above | every panel | Bodies in a shared-folder annex bind identically to inline bodies, for `.sv`/`.cl`/`.na` heads |
| Integration app + client | `endpoints.sv.jac`, `frontend.cl.jac` | `POST /walker/PostMessage`, `POST /walker/ListMessages`, `GET /` (SPA) | `GuestbookPanel` | Guestbook from the jac template; typed `list[Message]` reports |

**Webhooks have no panel on purpose.** `/webhook/*` needs an `X-API-Key` plus
an HMAC-SHA256 signature over the raw body. Signing in the browser would mean
shipping the signing secret to it, so that surface stays in
`tests/test_webhook.py` where the secret belongs.

## The GUI bench

`GET /` serves a panel per feature row. It is the human twin of `tests/`: the
pytest suite asserts the wire contract, the page lets you drive it by hand and
look at the raw envelope.

Panels call the server the idiomatic way — `sv import` plus `root spawn` or a
direct function call — because that generated call path is itself part of what
a conversion must reproduce. Where a panel *cannot* use it, that is a finding,
not a style choice; each one is recorded under "Client call-path limits" below.

Auth is a page-level switch (`AuthBar`): roughly half the matrix is auth-gated,
and the buttons relabel to "(expect 401)" when logged out, so the two halves
are visible without reading the source.

## Wire contracts observed against `jac start` (baseline truths for parity)

- Envelope: `{ok, type, data: {result, reports}, error, meta: {extra: {http_status}}}`;
  walker `result` includes `_jac_type`/`_jac_id`/`_jac_archetype` and echoed fields.
- Register: `POST /user/register` with `{"identities": [{"type": "username", "value": u}], "credential": {"type": "password", "password": p}}` -> 201.
- Login: `POST /user/login` with `{"identity": {...}, "credential": {...}}` (singular) -> `data.token`, `data.root_id`, `data.role`.
- Functions: `POST /function/<name>`, auth-gated unless `def:pub`; result in `data.result`, empty `reports`.
- Only names imported into the entry module are exposed (walkers, functions,
  AND @schedule/@subscribe carriers); defining them in a submodule is not enough.
  This holds for names whose bodies live in an impl annex, and for native names
  re-exported through an `sv` module.
- `++>` returns the created node itself (not a list).
- SSE: `data: <json>` frames then `event: end` + `data: {}`.
- WebSocket `/ws/<Walker>`: send one JSON message of walker fields, receive one
  `{ok, data: {result, reports}}` frame per message. The auth socket takes its
  token as `?token=` (a browser cannot set headers on a WS handshake).
- Webhook without API key: 422 (validation), not 401.
- kvstore without redis: 200-path fails with `EXECUTION_ERROR` envelope ("Redis URL not found in configuration").
- MockLLM returns the raw scripted string; it bypasses typed parsing, so
  `Classify` reports the JSON string, not a `Review` object.
- The browser stores its token at `localStorage["jac_token"]`; the generated
  client reads it via `globalThis.__jacGetLocalStorage__`.
- `[scale.microservices] enabled = false` is required locally — and does not
  stay false on its own; see bug 10.
- `[scale.events] enabled = true` required for @subscribe delivery (LocalEventStream without redis).
- Scheduler: static `@schedule` tasks run via the core scheduler without
  APScheduler; APScheduler (capability `scheduler`) is only needed for dynamic jobs.

## Client call-path limits (found by wiring the GUI)

These are limits of the generated `cl -> sv` client, all reproduced from a
browser against `jac start`. They matter for conversion because each one is a
place where the typed call path and the HTTP surface disagree — a converter
that reproduces only the HTTP surface will still break these callers.

- **C1 — `root spawn` ignores `@restspec` routing.** A walker routed to
  `GET /api/v1/status` is still called as `POST /walker/ApiStatus` by the
  generated client, which answers `405 Method Not Allowed`. So a
  `@restspec`-routed walker is unreachable from `cl` via the typed call and
  only works when fetched at its real route. `RestPanel` fetches them.
- **C2 — `root spawn` cannot send multipart.** `__doWalkerFetch` always sends
  `JSON.stringify(fields)` with `Content-Type: application/json`, so a walker
  with an `UploadFile` field cannot be called through it at all. `UploadPanel`
  hand-builds `FormData`. If a conversion ever teaches the client multipart,
  that panel should get simpler.
- **C3 — a 401 is swallowed.** On 401 the generated client deletes the stored
  token and returns a bare `{}` — no throw, no signal. A caller that does
  `(root spawn W()).reports` gets `undefined` and the user is silently logged
  out. `RestPanel._reports` names this shape instead of rendering `undefined`.

## jac bugs found while building this (fix in jaseci repo)

1. FIXED: backticked `` `root `` entry trigger emitted `lambda: root` (jaclib
   function, not the `Root` class) -> `issubclass()` TypeError at spawn.
   Fixed in pyast_gen_pass + regression test in tests/language/test_bugs.jac
   (branch `fix/backtick-root-entry-trigger`).
2. OPEN (jaseci-labs/jac#7518): `jac run`/`jac start` hangs forever when `DATABASE_HOST`/`MONGODB_URI`
   env vars point at an unreachable Mongo (pymongo server-selection blocks with
   no timeout, no error message).
3. OPEN (jaseci-labs/jac#7519): microservice auto-detection scans files outside the entry import
   closure (`unsupported/sv_micro.jac` triggered it) and then derives wrong
   service filenames (`features.rest_basic.jac`, `endpoints.jac` instead of
   `endpoints.sv.jac`), so auto-split services can never boot.
9. OPEN (jaseci-labs/jac#7520): under `jac start` the static @schedule task gets registered twice
   with mismatched class identity; one copy runs (beats advance), the
   phantom copy logs "Error executing task 'HeartbeatTick': Invalid walker
   object" every tick. Still reproduces; the log is noisy but beats do advance.
4. FIXED: `jac start --scale` could not deploy from a macOS driver: the app
   seal exec'd the linux pod binary on the host (Exec format error). The seal
   now runs in a throwaway linux container (branch
   `fix/k8s-deploy-macos-and-local-clusters`).
5. FIXED: the bundle PVC hardcoded ReadWriteMany, which k3s/kind/minikube
   local-path provisioners cannot bind; single-node clusters now fall back to
   ReadWriteOnce, with a `bundle_access_mode` override (same branch).
6. FIXED: `_deploy_databases` appended MONGODB_URI/REDIS_URL secret refs to
   env_list AFTER the container spec had copied it, so the app pod never
   received the provisioned database connections and silently fell back to
   pod-local sqlite while Mongo/Redis ran unused (same branch).
7. UX GAP: the deploy provisions Redis but the pod's `jac install` only adds
   the redis pip package if jac.toml declares a matching capability intent;
   this project declares `[scale.database] backend` and `[scale.events]
   broker` for that reason. Deploy-provisioned services should probably imply
   their capability automatically.
8. FIXED: the client (browser) compile path skips the type checker that
   stamps `call_kind`, so Python-builtin calls in cl code (e.g. `enumerate`
   in the guestbook's comprehension) lowered to bare identifiers and crashed
   the SPA at render with "enumerate is not defined". The ES codegen now
   classifies calls itself when call_kind is unset (same branch as the
   deploy fixes).
10. OPEN — **`jac start` rewrites the user's `jac.toml`.** On a cold compile it
    auto-detects the `sv import` in `frontend.cl.jac` (a *client* importing
    server types — the normal, documented way to declare the backend) and
    flips `[scale.microservices] enabled = false` to `true`, editing the file
    on disk. It then splits out an `endpoints` service that dies immediately
    with `jac: error: unrecognized arguments: --no_client`, leaves it
    unhealthy, boots the gateway anyway, and answers every walker with
    `404 {"code": "NOT_FOUND", "message": "Not found on any service"}`. Two
    bugs stacked: a tool silently mutating a config the user set, and the
    resulting split being unbootable. Distinct from bug 3 — that one was about
    *which files* the scan reads; this is about it writing to the project and
    overriding an explicit `false`. Reproduce: set `enabled = false`, clear the
    compile cache, `jac start`, then `git diff jac.toml`.
11. FIXED — **no `WebSocket` / `FormData` stubs for client code.**
    `compiler/type_system/js_globals.pyi` declared `fetch`, `location`, `JSON`,
    `TextDecoder`, ... but had no `WebSocket` or `FormData`, and `_Window` had
    no member for either; `dom_types.pyi` has `localStorage` but not
    `FormData`. So `new(WebSocket, url)` in `.cl.jac` failed to typecheck
    (E1053) even though both are ordinary browser globals the emitted JS can
    reach — hit by any client talking to its own `/ws/` walkers, or uploading
    to its own `UploadFile` walker.
    Fixed by adding `Blob`, `File`, `FormData` (the WHATWG body types) and
    `WebSocket`, `EventSource`, `MessageEvent`, `CloseEvent` (the push-side
    transports) to `js_globals.pyi`. They stay client-gated: server code still
    rejects `WebSocket` with the same E1053, which is the design intent.
12. FIXED — **`glob X: any;` shadowed the browser global it meant to name.**
    The obvious workaround for 11 — declaring `glob WebSocket: any;` as an
    extern — type-checked cleanly and then failed at runtime with
    `TypeError: undefined is not a constructor`. A silent trap: `jac check`
    green, page broken only on click.
    Root cause: [`esast_gen_pass.impl.jac`][esast] emitted a
    `VariableDeclaration` even when the assignment had no initializer, so the
    declaration lowered to a module-scope `let WebSocket;` that shadowed the
    real constructor.
    The server codespace already got this right — Python lowers the same
    construct to a bare annotation that creates no binding, which is directly
    testable: `glob len: any;` in a `.jac` file leaves `len` resolving to the
    builtin (`print(len([1,2,3]))` still prints `3`). Fixed by treating an
    initializer-less `glob` as ambient in the client codespace too, so the two
    agree. Regression test: `initializer-less glob is ambient and emits no
    binding` in `tests/compiler/passes/ecmascript/test_esast_gen_pass.jac`.

    [esast]: https://github.com/jaseci-labs/jaseci/blob/main/jac/jaclang/compiler/passes/ecmascript/impl/esast_gen_pass.impl.jac

13. OPEN — **a non-`:pub` client symbol fails at BUNDLE time, not check time.**
    A `.cl.jac` module importing a symbol that a sibling declared without
    `:pub` (`obj Res` / `glob PALETTE` rather than `obj:pub` / `glob:pub`)
    type-checks green — `jac check` reported 55/55 passed — and then rollup
    fails the bundle with `"PALETTE" is not exported by "compiled/Bench.js"`.
    `jac start` serves that as a bare `<h1>503 Service Unavailable</h1>` with
    no hint of the cause; the real error is buried in the server log.
    The compile-time and bundle-time notions of "exported" disagree, and the
    failure surfaces at the worst possible moment. `jac check` should reject a
    cross-module import of a non-`:pub` client symbol.
    Reproduce: drop `:pub` from `Res`/`PALETTE` in
    `components/Bench.cl.jac`, `jac check .` (green), then `jac start` -> 503.

## Conversion gaps: final status (Phase 3 complete)

1. CLOSED: scheduler wired into ejected main.py (@schedule symbols register
   with the vendored core scheduler; no HTTP endpoint emitted).
2. CLOSED: protocol=WEBSOCKET walkers mount as /ws/ routes (token handshake,
   result frames, broadcast fan-out); WS *functions* still audit-blocked.
3. CLOSED: protocol=WEBHOOK walkers mount at /webhook/ behind X-API-Key +
   HMAC-SHA256 + replay window; /api-key/create ships in the output.
4. CLOSED: publish/@subscribe lowered to an in-process broker adapter.
5. CLOSED: kvstore lowered to a redis-py adapter satisfying the same import
   path; unsupported scale imports still fail the audit loudly.
6. CLOSED: MTIR meaning-metadata pickled to backend/mtir.pkl and hydrated at
   boot; the prompt-fidelity test pins byte-identical prompts vs jac start.
7. OPEN (jaseci-labs/jac#7521): ~25-30% dead weight in the vendored runtime
   closure (optimization, not correctness).
8. BY DESIGN: `sv` microservice splits remain unsupported; the audit refuses
   them with a clear message.
9. UNTESTED: the `sv -> na` bridge has no converted-output story yet. Under
   `jac start` the native module is JIT-compiled into the same process and
   called over a ctypes trampoline; what `jac build --as source` should emit
   for that seam (ship the JIT? precompile a `.so`? refuse?) is undecided, so
   `make test-converted` has not been run against `features/native.sv.jac`.
   The `"via": "native"` tag in every native report exists to make a silent
   demotion to a Python reimplementation detectable.

Version caveat: goldens (incl. the byllm prompt) are recorded against the
jac version that serves the baseline; a cluster running a different release
may legitimately drift on prompt text.
