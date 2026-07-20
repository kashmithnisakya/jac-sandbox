"""Native (na) compute reached over the sv -> na bridge.

`na` has no server: these walkers are the only path from HTTP to machine code,
so what is really under test is the compiler-generated ctypes trampoline.

The expected values are picked to be independently checkable rather than
recorded — fib(40) and pi(10_000) are facts, not baselines. A bridge that
silently degraded to a stub, or lost precision crossing the boundary, fails
these; it would not fail a golden recorded from the same broken build.
"""

from helpers import check_golden, reports_of


def test_native_fib(client):
    r = client.post("/walker/NativeFib", json={"n": 40})
    assert r.status_code == 200
    report = reports_of(r.json())[0]
    assert report == {"n": 40, "fib": 102334155, "via": "native"}
    check_golden("native_fib", r.json())


def test_native_fib_base_cases(client):
    for n, expected in ((0, 0), (1, 1), (2, 1), (10, 55)):
        r = client.post("/walker/NativeFib", json={"n": n})
        assert r.status_code == 200
        assert reports_of(r.json())[0]["fib"] == expected, f"fib({n})"


def test_native_count_primes(client):
    """1229 primes below 10_000 — an arithmetic fact the JIT must reproduce."""
    r = client.post("/walker/NativePrimes", json={"limit": 10000})
    assert r.status_code == 200
    assert reports_of(r.json())[0] == {
        "limit": 10000,
        "primes": 1229,
        "via": "native",
    }


def test_native_checksum_is_deterministic_and_sensitive(client):
    """Same input -> same digest; one changed byte -> different digest.

    Pins that `str` really crosses the boundary. A bridge that passed a null
    or a truncated pointer would still return *a* number, and a test that only
    checked "returns an int" would pass while the string never arrived.
    """

    def checksum(data: str) -> int:
        r = client.post("/walker/NativeChecksum", json={"data": data})
        assert r.status_code == 200
        return reports_of(r.json())[0]["checksum"]

    assert checksum("jac-sandbox") == checksum("jac-sandbox")
    assert checksum("jac-sandbox") != checksum("jac-sandbo")
    assert checksum("") == 0

    # The na impl is a base-31 rolling hash mod 1e9+7; recompute it here so a
    # drift in the native lowering is caught, not just a change in the answer.
    expected = 0
    for ch in "jac-sandbox":
        expected = (expected * 31 + ord(ch)) % 1000000007
    assert checksum("jac-sandbox") == expected


def test_native_walkers_are_public(client):
    """The na panel in the GUI runs logged-out, so these must not be gated."""
    for walker in ("NativeFib", "NativeChecksum", "NativePrimes"):
        r = client.post(f"/walker/{walker}", json={})
        assert r.status_code == 200, f"{walker} should be :pub"
