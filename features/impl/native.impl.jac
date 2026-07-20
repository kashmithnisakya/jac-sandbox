"""Bodies for `features/native.sv.jac`.

Each report tags `"via": "native"` so a conformance test can tell a real
bridge crossing from an accidental Python-side reimplementation."""

impl NativeFib.go with Root entry {
    report {"n": self.n, "fib": fib(self.n), "via": "native"};
}

impl NativeChecksum.go with Root entry {
    report {"data": self.data, "checksum": checksum(self.data), "via": "native"};
}

impl NativePrimes.go with Root entry {
    report {"limit": self.limit, "primes": count_primes(self.limit), "via": "native"};
}
