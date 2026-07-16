"""Streaming: a generator-reporting walker becomes an SSE endpoint."""

walker:pub SseTicker {
    has count: int = 3;

    can go with Root entry {
        def ticks -> str {
            for i in range(self.count) {
                yield f"tick-{i}";
            }
        }
        report ticks();
    }
}
