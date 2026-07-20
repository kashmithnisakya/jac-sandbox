"""Native panel: drives the `sv -> na` bridge from the browser.

The click path here is cl -> sv -> na: React calls a walker, the walker calls
LLVM-compiled machine code over the ctypes bridge, and the number comes back.
All three codespaces in one round trip.

Watch the millisecond count as much as the answer — see the impl annex."""

sv import from features.native { NativeFib, NativeChecksum, NativePrimes }

import from .Bench { Panel, Row, TextInput, RunButton, ResultView, Res, statusOf }

def:pub NativePanel -> JsxElement {
    has fibN: str = "30",
        data: str = "jac-sandbox",
        limit: str = "10000",
        out: any = None,
        busy: bool = False;

    async def run(probe: str) -> None;

    return
        <Panel
            title="Native (na) via the sv bridge"
            blurb="Walkers calling LLVM-compiled machine code. na has no server of its own, so this is the only way it reaches HTTP."
            wire="POST /walker/NativeFib | /walker/NativeChecksum | /walker/NativePrimes"
            status={statusOf(out)}
        >
            <Row>
                <TextInput
                    value={fibN}
                    onChange={lambda (e: any) { fibN = e.target.value; }}
                    placeholder="n"
                    width="5rem"
                />
                <RunButton label="fib(n)" onClick={lambda { run("fib"); }} busy={busy}/>
                <TextInput
                    value={data}
                    onChange={lambda (e: any) { data = e.target.value; }}
                    placeholder="data"
                />
                <RunButton
                    label="checksum"
                    onClick={lambda { run("checksum"); }}
                    busy={busy}
                />
                <TextInput
                    value={limit}
                    onChange={lambda (e: any) { limit = e.target.value; }}
                    placeholder="limit"
                    width="6rem"
                />
                <RunButton
                    label="count_primes"
                    onClick={lambda { run("primes"); }}
                    busy={busy}
                />
            </Row>
            <ResultView value={out}/>
        </Panel>;
}
