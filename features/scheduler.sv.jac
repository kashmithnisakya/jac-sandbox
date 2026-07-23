"""Scheduled jobs: a static interval walker appends to an in-memory log,
mirroring the scale test-fixture pattern; a pub walker exposes the log so
tests can verify the job actually fired.

Bodies in `features/impl/scheduler.impl.jac`. The @schedule decorator stays
on the decl so the carrier registers from the entry import closure."""

glob heartbeat_log: list = [];

@schedule(trigger=ScheduleTrigger.STATIC, interval=1.0)
walker HeartbeatTick {
    can go with Root entry;
}

walker:pub ReadHeartbeat {
    can go with Root entry;
}

glob dyn_log: list = [];

@schedule(trigger=ScheduleTrigger.DYNAMIC)
walker DynPing {
    has msg: str = "default-msg";

    can go with Root entry {
        dyn_log.append(self.msg);
    }
}

walker:pub ReadDynLog {
    can go with Root entry {
        report {"count": len(dyn_log), "msgs": list(dyn_log)};
    }
}
