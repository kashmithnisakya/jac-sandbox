"""Handlers for `components/NativePanel.cl.jac`.

The `ms` on each result is as much the point as the number: count_primes(10_000)
crossing into machine code and back should land in single-digit milliseconds.
If it ever creeps toward Python territory, the bridge has stopped bridging."""

impl NativePanel.run(probe: str) -> None {
    busy = True;
    started = Date.now();
    try {
        body: any = None;
        if probe == "fib" {
            body = (root spawn NativeFib(n=int(fibN or "0"))).reports as any;
        } elif probe == "checksum" {
            body = (root spawn NativeChecksum(data=data)).reports as any;
        } elif probe == "primes" {
            body = (root spawn NativePrimes(limit=int(limit or "0"))).reports as any;
        }
        out = Res(ok=True, ms=int(Date.now() - started), body=body);
    } except Exception as e {
        out = Res(ok=False, ms=int(Date.now() - started), body={"error": str(e)});
    }
    busy = False;
}
