# Feature Matrix

The conversion burn-down list. A converter feature is done when its row's
conformance tests pass against BOTH `jac start` and the converted output.

| Feature | Module | Endpoints / surface | Expected behavior |
| --- | --- | --- | --- |
| Pub vs auth walkers | `features/rest_basic.jac` | `POST /walker/PingPub` (open), `POST /walker/PingAuth` (401 without token) | Auth default is compiler-decided (`:pub` = open) |
| Graph writes + typed reads | `features/rest_basic.jac` | `POST /walker/AddItem`, `POST /walker/ListItems` | Items created, listed from user root |
| Node-addressed spawn | `features/rest_basic.jac` | `POST /walker/VisitItem/{node_id}` | Spawns on an arbitrary node by id |
| Function endpoints | `features/rest_basic.jac` | `POST /function/sandbox_health` (pub), `POST /function/add_two` (auth) | Return values, not reports |
| Custom REST routes | `features/restspec_routes.jac` | `GET /api/v1/status`, `POST /api/v1/echo` | `@restspec(method, path)` overrides |
| SSE streaming | `features/streaming.jac` | `POST /walker/SseTicker` | Generator report streams as SSE frames |
| File uploads | `features/uploads.jac` | `POST /walker/UploadDoc` (auth), `POST /walker/UploadPublic` (pub) | Multipart UploadFile fields |
| Persistence + isolation | `features/persistence.jac` | `POST /walker/AddNote`, `POST /walker/CountNotes` | Notes survive restarts; user A cannot see user B's notes |
| Permissions | `features/permissions.jac` | `POST /walker/ShareNote`, `POST /walker/ReadShared` | `grant(ReadPerm)` + cross-user read by node id |
| Scheduled jobs | `features/scheduler.jac` | `@schedule` interval walker + `POST /walker/ReadHeartbeat` | Beats accumulate while server runs; CONVERSION GAP: ejected main.py never starts the scheduler |
| WebSockets | `features/websocket.jac` | `ws /ws/WsEcho` (pub), `ws /ws/WsBroadcast` (broadcast), `ws /ws/WsPrivate` (auth) | CONVERSION GAP: eject demotes these to plain POST |
| Webhooks | `features/webhook.jac` | `POST /webhook/HookOrderPaid`, `POST /webhook/HookPing` | HMAC + replay verification; CONVERSION GAP: eject drops HMAC |
| Events | `features/events.jac` | `POST /walker/EmitEvent`, `POST /function/read_events` | `publish` -> `@subscribe` handler delivery |
| Key-value store | `features/kvstore.jac` | `POST /walker/KvPut`, `POST /walker/KvGet` | Redis-backed kvstore; lazy client so boot works without redis; CONVERSION GAP: scale imports crash ejected boot |
| Typed by llm() | `features/byllm_typed.jac` | `POST /walker/Classify` | Structured output via sem strings + MockLLM; CONVERSION GAP: MTIR metadata dropped on eject (prompt drift) |
| by llm() with tools | `features/byllm_tools.jac` | `POST /walker/Advise` | ReAct tool loop, scripted MockLLM |
| Integration app + client | `endpoints.sv.jac`, `frontend.cl.jac` | `POST /walker/PostMessage`, `POST /walker/ListMessages`, `GET /` (SPA) | Guestbook from the jac template; typed `list[Message]` reports |
| Audit loud-failure case | `unsupported/sv_micro.jac` | none (NOT imported by main.jac) | Converting a project that includes `sv import` must fail loudly |

## Wire contracts observed against `jac start` (baseline truths for parity)

- Envelope: `{ok, type, data: {result, reports}, error, meta: {extra: {http_status}}}`;
  walker `result` includes `_jac_type`/`_jac_id`/`_jac_archetype` and echoed fields.
- Register: `POST /user/register` with `{"identities": [{"type": "username", "value": u}], "credential": {"type": "password", "password": p}}` -> 201.
- Login: `POST /user/login` with `{"identity": {...}, "credential": {...}}` (singular) -> `data.token`, `data.root_id`, `data.role`.
- Functions: `POST /function/<name>`, auth-gated unless `def:pub`; result in `data.result`, empty `reports`.
- Only names imported into the entry module are exposed (walkers, functions,
  AND @schedule/@subscribe carriers); defining them in a submodule is not enough.
- `++>` returns the created node itself (not a list).
- SSE: `data: <json>` frames then `event: end` + `data: {}`.
- WebSocket `/ws/<Walker>`: send one JSON message of walker fields, receive one
  `{ok, data: {result, reports}}` frame per message.
- Webhook without API key: 422 (validation), not 401.
- kvstore without redis: 200-path fails with `EXECUTION_ERROR` envelope ("Redis URL not found in configuration").
- MockLLM returns the raw scripted string; it bypasses typed parsing, so
  `Classify` reports the JSON string, not a `Review` object.
- `[scale.microservices] enabled = false` is required locally: `sv import`
  anywhere in the project (even in a module main.jac never imports) otherwise
  flips auto-microservice mode, and the split services fail to boot from
  dotted module names (real jac bugs, see below).
- `[scale.events] enabled = true` required for @subscribe delivery (LocalEventStream without redis).
- Scheduler: static `@schedule` tasks run via the core scheduler without
  APScheduler; APScheduler (capability `scheduler`) is only needed for dynamic jobs.

## jac bugs found while building this (fix in jaseci repo)

1. FIXED: backticked `` `root `` entry trigger emitted `lambda: root` (jaclib
   function, not the `Root` class) -> `issubclass()` TypeError at spawn.
   Fixed in pyast_gen_pass + regression test in tests/language/test_bugs.jac
   (branch `fix/backtick-root-entry-trigger`).
2. OPEN: `jac run`/`jac start` hangs forever when `DATABASE_HOST`/`MONGODB_URI`
   env vars point at an unreachable Mongo (pymongo server-selection blocks with
   no timeout, no error message).
3. OPEN: microservice auto-detection scans files outside the entry import
   closure (`unsupported/sv_micro.jac` triggered it) and then derives wrong
   service filenames (`features.rest_basic.jac`, `endpoints.jac` instead of
   `endpoints.sv.jac`), so auto-split services can never boot.
9. OPEN: under `jac start` the static @schedule task gets registered twice
   with mismatched class identity; one copy runs (beats advance), the
   phantom copy logs "Error executing task 'HeartbeatTick': Invalid walker
   object" every tick.
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
7. OPEN: ~25-30% dead weight in the vendored runtime closure (optimization,
   not correctness).
8. BY DESIGN: `sv` microservice splits remain unsupported; the audit refuses
   them with a clear message.

Version caveat: goldens (incl. the byllm prompt) are recorded against the
jac version that serves the baseline; a cluster running a different release
may legitimately drift on prompt text.
