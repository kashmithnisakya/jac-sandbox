# Jac → Python/JS Conversion: End-to-End Execution Plan

**Goal:** `jac build --as source` run on this sandbox emits a converted project
(backend FastAPI + frontend Vite/React) that passes the exact same conformance
suite as the live `jac start` server, with zero silent feature demotion.

**Where the work lands:**
- Test bench: `jaseci_labs/jac-sandbox` (this repo, new)
- Converter: `jaseci_labs/jaseci` monorepo, inside the existing
  `jac build --as source` path (`jac/jaclang/cli/commands/impl/eject.impl.jac`,
  `jac/jaclang/cli/commands/eject_targets/backend.jac`,
  `jac/jaclang/publish/runtime_vendor.jac`). No new external tool.
- References for feature idioms: `CA-Internal` (restspec, pub walkers, by llm,
  sv import) and `this_is_jac` (client pages, by llm).

**Definition of done:**
```
cd jac-sandbox
jac build --as source          # converts with a loud capability audit
make test SERVER=converted     # same suite that is green on SERVER=jac
```

---

## Phase 0 — Baseline and recon (jaseci repo, ~0.5 day)

0.1 Run `jac build --as source` on a scratch project end-to-end in a fresh
    venv; record exactly what works today (walker endpoints, auth, SSE,
    uploads, restspec paths, sqlite persistence, vendored runtime, frontend).

0.2 Fix the known codegen bug found during the survey: a backticked lowercase
    `` `root `` entry trigger compiles to `@set_trigger(lambda: root)` without
    importing `root` from jaclib → NameError at spawn. Add a regression test
    that actually executes the walker (the existing eject test only asserts
    emitted text).

0.3 Write the coverage gap list into the sandbox manifest (Phase 1.4) from the
    survey findings: scheduler never wired into generated main.py, websocket
    walkers demoted to POST, webhook walkers lose HMAC, events/@subscribe
    absent, scale kvstore imports crash at boot, byllm MTIR metadata dropped
    (prompt drift), ~25-30% dead weight in the vendored closure.

## Phase 1 — Build the sandbox feature matrix (~1 day)

One small module per feature so conversion failures are attributable; one
integration app because coupling bugs only appear in combination.

```
jac-sandbox/
├── jac.toml                    pinned jac version; [scale]; [byllm] MockLLM default
├── .env.example
├── main.jac                    entry; imports all feature modules
├── app.jac                     integration app (todo-style, combines features)
├── features/
│   ├── rest_basic.jac          pub vs auth walkers, node-addressed spawn, reports vs returns
│   ├── restspec_routes.jac     custom method/path, GET query params
│   ├── streaming.jac           generator walker → SSE
│   ├── uploads.jac             UploadFile multipart
│   ├── persistence.jac         graph across requests, save/commit, per-user root isolation
│   ├── permissions.jac         grant/revoke, allroots
│   ├── scheduler.jac           @schedule cron + interval job writing a heartbeat node
│   ├── websocket.jac           @restspec(protocol=WEBSOCKET) walker
│   ├── webhook.jac             @restspec(protocol=WEBHOOK) walker (HMAC + replay window)
│   ├── events.jac              @subscribe / publish
│   ├── kvstore.jac             scale persistence lib (redis/mongo kvstore)
│   ├── storage.jac             store() object storage
│   ├── byllm_typed.jac         typed by llm(): nested dataclass sem strings + enum members
│   └── byllm_tools.jac         by llm(tools=[...]) + streaming
├── unsupported/
│   └── sv_micro.jac            sv import microservice split — EXCLUDED by default;
│                               exists so the audit's loud-failure path has a test
├── pages/
│   └── home.cl.jac             client page calling walkers through the envelope
├── FEATURES.md                 manifest: feature → module → endpoints → expected behavior
└── tests/                      (Phase 2)
```

Rules: every module < ~100 lines; use idioms from CA-Internal/this_is_jac;
avoid the backticked-root trigger until 0.2 lands; walker names globally
unique (converter aborts on duplicates).

**Acceptance:** `jac start` boots and every feature is exercisable by hand.

## Phase 2 — Conformance harness before the converter (~1 day)

pytest suite parameterized by base URL, so one suite serves both servers.

2.1 Plumbing: httpx client, `websockets` client, webhook HMAC signer,
    SSE line reader, register/login fixture (two users, for isolation tests),
    wait-for-heartbeat helper for scheduler jobs.

2.2 One test file per feature module, asserting on the full wire envelope
    (`{ok, type, data, error, meta}`), status codes, and auth behavior; the
    per-user-root test proves user A cannot see user B's nodes.

2.3 byllm determinism: MockLLM for behavior tests, plus a prompt-capture test
    that snapshots the outgoing prompt text + JSON schema (not the model
    reply). This snapshot is the prompt-drift detector between jac and
    converted runs.

2.4 Golden fixtures: record envelopes from the `jac start` run;
    `make baseline` regenerates them deliberately.

2.5 Runner: `make test SERVER=jac` (boots `jac start`) and
    `make test SERVER=converted` (runs `jac build --as source`, installs
    requirements in a fresh venv, boots the converted server).

**Acceptance:** 100% green on `SERVER=jac`. This is the frozen baseline.

## Phase 2.5 — Deploy the sandbox to local Kubernetes (~0.5-1 day)

Deploy the sandbox with `jac start --scale` to a local cluster BEFORE converter work,
so bugs in the jac serving/deploy path get found and fixed while the
conformance suite is fresh.

2.5.1 Cluster: k3d cluster `jac` (proven on this machine; Docker Desktop k8s
      pods have no egress). `minikube` is the fallback if k3d misbehaves.

2.5.2 Deploy the sandbox (`jac start --scale` k8s realization: manifests, Mongo/Redis
      provisioning as configured). Smoke-check pods, ingress, and the admin
      portal.

2.5.3 Run the Phase 2 conformance suite against the cluster URL
      (`make test SERVER=cluster BASE_URL=...`). The suite is already
      parameterized by base URL, so this is free.

2.5.4 Every failure here is a jac-code bug (scale/deploy/runtime), not a
      sandbox bug: fix each in the jaseci repo with its own small PR +
      regression test before moving on.

**Acceptance:** conformance suite green against the cluster deployment.

## Phase 3 — Converter work in the jaseci repo (~4-6 days)

Burn down the matrix; each item merges only when its sandbox module passes
parity. Ordered so honesty comes first, then the named features, then fidelity
and polish. Follow the repo PR workflow (fork/upstream remotes, release-note
fragment matching PR number, small PRs).

3.1 **Capability audit pass (first, unblocks everything).** At convert time,
    scan restspec protocols, `jaclang.scale.*` imports, `@schedule`, `sv`
    blocks, and byllm usage. Emit a support report; any unsupported feature =
    non-zero exit with an actionable message. Silent demotion becomes
    structurally impossible. Test: converting `unsupported/sv_micro.jac`
    fails loudly; converting the default sandbox passes.

3.2 **Scheduler.** Wire APScheduler (or the vendored Scheduler) into the
    generated main.py lifespan; static jobs from `@schedule` decorators.
    (Contract reference: runtimelib/impl/server.impl.jac scheduler
    registration, ~lines 2356-2367.)

3.3 **WebSockets.** Generate an explicit FastAPI WebSocket route per
    `protocol=WEBSOCKET` walker: token handshake, JSON frame shape matching
    scale's contract (reference: scale/server/impl/serve.endpoints.impl.jac).

3.4 **Webhooks.** Generate an HMAC-SHA256 + timestamp-replay-window route per
    `protocol=WEBHOOK` walker using stdlib hmac/hashlib; API keys via env.

3.5 **kvstore / scale persistence imports.** Emit an idiomatic adapter module
    (pymongo / redis-py direct) when detected; audit-fail if the backend
    isn't configured rather than crashing at boot.

3.6 **Events (@subscribe/publish).** In-process broker for the default case,
    redis-streams adapter when redis is configured; otherwise audit-fail.

3.7 **byllm fidelity.** Serialize `JacProgram.mtir_map` (plain dataclasses) to
    `ai_metadata.json` beside the generated code + a small hydration shim so
    `fetch_mtir` finds it. Proof: the Phase 2.3 prompt snapshot is identical
    between `jac start` and the converted server.

3.8 **Output layout + idiomatic polish.**
    - Split generated main.py into `api/` (routes_walkers, routes_auth,
      routes_webhooks, ws, schemas) per the report's target layout.
    - Rename the vendored runtime namespace to a project-local `kernel/`
      package (mechanical; `_rewrite_imports` already exists).
    - Trim closure dead weight: split runtimelib server so the FastAPI path
      stops dragging client_bundle/sealed_serve/sv_client; target ≤ ~8k LOC.

3.9 **Envelope compatibility.** Keep the TransportResponse shape and
    `/walker/<name>[/<node_id>]` conventions byte-compatible; the parity
    suite enforces this on every PR.

## Phase 4 — End-to-end validation + CI (~1 day)

4.1 Fresh-machine test: `jac build --as source` on the sandbox; converted
    backend boots in a clean venv with only requirements.txt; frontend builds
    with stock npm and the client page round-trips a walker call.

4.2 Full parity: `make test SERVER=converted` green; envelope diffs empty.

4.3 CI (GitHub Actions or `make ci`): job 1 = baseline vs `jac start`,
    job 2 = convert + test converted. Any drift fails.

## Phase 5 — Cleanup + docs (~0.5 day)

5.1 Remove anything the new path obsoletes (dead vendored modules, the
    fragile `_js_exports_app` text-sniffing if replaced by manifest data).

5.2 Sandbox README: how to add a new feature row (module + manifest + test).

5.3 Update jac docs: `jac build --as source` coverage matrix = FEATURES.md.

---

## Notes and risks

- The converter and runtime are themselves written in Jac; converter changes
  are .jac edits in the jaseci repo, and dev-mode hooks are slow there.
- Websocket/webhook/events contracts should match scale behaviorally, but
  exact frame-level parity may need pragmatic golden-fixture updates; any
  deliberate contract change must be recorded in FEATURES.md.
- Estimated total: 9-11 working days of focused effort, parallelizable after
  Phase 2 (matrix rows are independent).
