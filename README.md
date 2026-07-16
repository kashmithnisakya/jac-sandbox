# jac-sandbox

Feature-matrix test bench for the Jac to Python/JS conversion effort.
One module per runtime feature under `features/`, the template guestbook as
the integration app, and a conformance suite that runs unchanged against any
server claiming to serve this project. See PLAN.md for the full roadmap and
FEATURES.md for the feature -> module -> endpoint matrix and observed wire
contracts.

## Quick start

```bash
make venv       # one-time: create .venv-tests with pytest/httpx/websockets
make serve      # boot the jac server on :8000 (strips the Mongo env vars)
make test       # run the conformance suite against BASE_URL (default :8000)
```

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
