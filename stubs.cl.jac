def:pub probe -> JsxElement {
    sock: any = new(WebSocket, "ws://x/y");
    sock.onopen = lambda (e: any) { sock.send("hi"); };
    sock.close(1000);
    form: any = new(FormData);
    form.append("a", "b");
    es: any = new(EventSource, "/stream");
    es.close();
    b: any = new(Blob, ["x"]);
    return <div>{b.size}</div>;
}
