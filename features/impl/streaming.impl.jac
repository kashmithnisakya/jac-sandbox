"""Body for `features/streaming.sv.jac`."""

impl SseTicker.go with Root entry {
    def ticks -> str {
        for i in range(self.count) {
            yield f"tick-{i}";
        }
    }
    report ticks();
}
