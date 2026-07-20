"""The `sv -> na` bridge: server walkers that call native machine code.

`na` code cannot host a walker or an endpoint — it has no Python runtime and
no server. So the native leg reaches HTTP (and the GUI) exactly one way: a
normal `sv` walker imports the native names and the compiler generates the
ctypes trampoline. These walkers are that seam, and the conversion must
reproduce it.

Bodies in `features/impl/native.impl.jac`."""

import from .native_compute { fib, checksum, count_primes }

walker:pub NativeFib {
    has n: int = 30;

    can go with Root entry;
}

walker:pub NativeChecksum {
    has data: str = "jac-sandbox";

    can go with Root entry;
}

walker:pub NativePrimes {
    has limit: int = 10000;

    can go with Root entry;
}
