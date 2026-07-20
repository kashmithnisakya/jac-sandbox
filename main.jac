"""jac-sandbox - Entry Point.

Feature-matrix test bench: imports every feature module so the server
registers the full surface, plus the guestbook integration app and its
client UI. See FEATURES.md for the feature -> module -> endpoint map."""

import from endpoints { Message, PostMessage, ListMessages }
import from features.rest_basic {
    PingPub,
    PingAuth,
    AddItem,
    ListItems,
    VisitItem,
    sandbox_health,
    add_two
}
import from features.restspec_routes { ApiStatus, ApiEcho }
import from features.streaming { SseTicker }
import from features.uploads { UploadDoc, UploadPublic }
import from features.persistence { AddNote, CountNotes }
import from features.permissions { ShareNote, ReadShared }
import from features.scheduler { HeartbeatTick, ReadHeartbeat }
import from features.websocket { WsEcho, WsBroadcast, WsPrivate }
import from features.webhook { HookOrderPaid, HookPing }
import from features.events { EmitEvent, read_events }
import from features.kvstore { KvPut, KvGet }
import from features.byllm_typed { Classify, read_llm_prompts }
import from features.byllm_tools { Advise }
import from features.native { NativeFib, NativeChecksum, NativePrimes }

# Client-side UI
cl {
    import from .frontend { app as ClientApp }

    def:pub app -> JsxElement {
        return <ClientApp/>;
    }
}
