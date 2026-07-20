"""Native codespace: pure compute compiled through LLVM, no Python runtime.

This is the `na` leg of the bench. It exists to pin the `sv -> na` bridge:
`features/native.sv.jac` imports these names and the compiler generates the
ctypes trampoline, so a walker (and therefore the GUI) can call machine code.

Everything here lives inside the native capability boundary (E5090): no
Python imports beyond the allowlist, no generators, no inline Python, no
`by llm()`. That restriction is the point — it is what the converter must
respect. Bodies are in `features/impl/native_compute.impl.jac`, which also
pins that an impl annex resolves for a `.na.jac` head.
"""

def fib(n: int) -> int;

def checksum(data: str) -> int;

def count_primes(limit: int) -> int;
