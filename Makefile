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

clean:
	rm -rf $(VENV) ejected
