"""Bodies for `features/native_compute.na.jac` — native codespace.

Iterative rather than recursive on purpose: these run inside the JIT, and the
bench wants deterministic wall-clock, not stack depth."""

impl fib(n: int) -> int {
    if n <= 1 {
        return n;
    }
    a = 0;
    b = 1;
    for _ in range(n - 1) {
        t = a + b;
        a = b;
        b = t;
    }
    return b;
}

impl checksum(data: str) -> int {
    h = 0;
    for ch in data {
        h = (h * 31 + ord(ch)) % 1000000007;
    }
    return h;
}

impl count_primes(limit: int) -> int {
    total = 0;
    n = 2;
    while n < limit {
        is_prime = True;
        d = 2;
        while d * d <= n {
            if n % d == 0 {
                is_prime = False;
                break;
            }
            d = d + 1;
        }
        if is_prime {
            total = total + 1;
        }
        n = n + 1;
    }
    return total;
}
