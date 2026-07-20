# jac-sandbox

Feature-matrix test bench for the Jac to Python/JS conversion effort.

One module per runtime feature under `features/`, the template guestbook as
the integration app, a GUI that drives every endpoint by hand, and a
conformance suite that runs unchanged against any server claiming to serve
this project. See FEATURES.md for the feature -> module -> endpoint matrix,
the observed wire contracts, and the running list of jac bugs this has found.

## Quick start

```bash
make venv       # one-time: create .venv-tests with pytest/httpx/websockets
make serve      # boot the jac server on :8000 (strips the Mongo env vars)
make test       # run the conformance suite against BASE_URL (default :8000)
```

Then open <http://localhost:8000> for the GUI bench.

## Two ways to drive it

The suite and the page test the same surface from opposite ends, and the
difference is the point:

- **`make test`** asserts the *wire*: raw HTTP/WS against the endpoints, with
  golden files pinning the envelopes. This is what runs in CI and what you
  point at a converted server.
- **the GUI** (`GET /`) asserts the *client*: each panel calls the server the
  idiomatic way (`sv import` + `root spawn` / direct function call), so it
  exercises the generated `cl -> sv` call path, which is itself part of what a
  conversion has to reproduce. Log in with the auth bar and the auth-gated half
  of the matrix comes alive; logged out, those buttons relabel to
  "(expect 401)".

A panel that *can't* use the typed call is a finding, not a style choice — the
three known cases are recorded as C1–C3 in FEATURES.md.

## Layout

```text
main.jac                     entry point — imports every feature so it registers
endpoints.sv.jac             guestbook data layer      -> impl/endpoints.impl.jac
frontend.cl.jac              GUI shell                 -> impl/frontend.impl.jac
features/*.sv.jac            one module per feature    -> features/impl/*.impl.jac
features/native_compute.na.jac   native (LLVM) compute -> features/impl/native_compute.impl.jac
components/*.cl.jac          one panel per feature     -> components/impl/*.impl.jac
tests/                       conformance suite + goldens
```

Every declaration is split from its body through the shared-folder impl annex
(`impl/<module>.impl.jac`), across all three codespaces — server (`sv`), client
(`cl`) and native (`na`). That is deliberate: file shape is part of what the
converter has to handle.

## Targets

| Target | What it does |
| --- | --- |
| `make serve` | `jac start` with `DATABASE_HOST`/`MONGODB_URI` stripped (jac hangs on unreachable Mongo) |
| `make test` | run the suite against `BASE_URL` (default `http://localhost:8000`) |
| `make baseline` | re-record the golden envelopes in `tests/goldens/` (deliberate act) |
| `make convert` | `jac build --as source` into `ejected/` |
| `make check` | type-check the project |

## Testing another server

```bash
BASE_URL=http://localhost:9000 make test          # converted server
BASE_URL=http://cluster.local make test           # k8s deployment
KVSTORE_MODE=ok make test                         # when redis is available
```

The suite creates fresh users per run, so rerunning against a long-lived
server is safe. Golden files pin normalized envelopes (ids/tokens stripped);
any wire drift fails the suite.

## Gotcha: `jac start` edits `jac.toml`

On a cold compile, `jac start` flips `[scale.microservices] enabled` from
`false` to `true` on disk, then serves 404s for every walker. If the bench
suddenly answers `{"code": "NOT_FOUND", "message": "Not found on any service"}`,
check `git diff jac.toml` and reset it. This is jac bug 10 in FEATURES.md.
