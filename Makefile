VENV := .venv-tests
PY := $(VENV)/bin/python
PYTEST := $(VENV)/bin/pytest
BASE_URL ?= http://localhost:8000

# jac hangs if these point at an unreachable Mongo (open jac bug), so every
# jac invocation strips them from the environment.
JAC := env -u DATABASE_HOST -u MONGODB_URI jac

.PHONY: venv serve test baseline convert check clean

venv:
	python3 -m venv $(VENV)
	$(PY) -m pip install -q -r tests/requirements.txt

serve:
	$(JAC) start

check:
	$(JAC) check .

test:
	BASE_URL=$(BASE_URL) $(PYTEST) tests -q

baseline:
	BASE_URL=$(BASE_URL) RECORD_GOLDENS=1 $(PYTEST) tests -q

convert:
	$(JAC) build --as source

test-converted: convert
	cd ejected/backend && python3 -m venv .venv && .venv/bin/pip install -q -r requirements.txt
	cd ejected/backend && { .venv/bin/uvicorn main:app --port 8010 > server.log 2>&1 & echo $$! > .pid; }; \
	sleep 10; \
	BASE_URL=http://localhost:8010 $(PYTEST) tests -q; status=$$?; \
	kill $$(cat ejected/backend/.pid) 2>/dev/null; exit $$status

clean:
	rm -rf $(VENV) ejected
