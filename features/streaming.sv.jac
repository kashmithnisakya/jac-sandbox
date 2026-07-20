"""Streaming: a generator-reporting walker becomes an SSE endpoint.

Body in `features/impl/streaming.impl.jac`, including the nested generator
`ticks` — an impl annex carrying a `yield` is itself part of the surface."""

walker:pub SseTicker {
    has count: int = 3;

    can go with Root entry;
}
