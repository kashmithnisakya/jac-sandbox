"""Guestbook panel: the integration app the bench is built around.

This is the one panel that is a real feature rather than a probe — it is the
jac template's guestbook, kept because an end-to-end app exercises the typed
`list[Message]` report path that the single-shot probes do not."""

sv import from endpoints { Message, PostMessage, ListMessages }

import from .MessageCard { MessageCard }
import from .Bench { Panel, Row, TextInput, RunButton, Hint }

def:pub GuestbookPanel -> JsxElement {
    has messages: list[Message] = [],
        author: str = "",
        text: str = "";

    can with entry {
        loadMessages();
    }

    async def loadMessages -> None;
    async def postMessage -> None;

    return
        <Panel
            title="Guestbook (integration app)"
            blurb="Typed list[Message] reports round-tripping through the graph. Persists across restarts."
            wire="POST /walker/PostMessage | /walker/ListMessages"
            status={"ok" if messages else "idle"}
        >
            <Row>
                <TextInput
                    value={author}
                    onChange={lambda (e: any) { author = e.target.value; }}
                    placeholder="Name"
                />
                <TextInput
                    value={text}
                    onChange={lambda (e: any) { text = e.target.value; }}
                    placeholder="Say something..."
                    width="18rem"
                />
                <RunButton label="Post" onClick={postMessage}/>
                <RunButton label="Reload" onClick={loadMessages} tone="ghost"/>
            </Row>
            {<Hint text="No messages yet — post one, it will survive a restart."/>
                if not messages
                else None}
            {[
                <MessageCard key={idx} author={msg.author} text={msg.text}/>
                for (idx, msg) in enumerate(messages)
            ]}
        </Panel>;
}
