"""Scheduled jobs: a static interval walker appends to an in-memory log,
mirroring the scale test-fixture pattern; a pub walker exposes the log so
tests can verify the job actually fired."""

glob heartbeat_log: list = [];

@schedule(trigger=ScheduleTrigger.STATIC, interval=1.0)
walker HeartbeatTick {
    can go with Root entry {
        heartbeat_log.append("beat");
    }
}

walker:pub ReadHeartbeat {
    can go with Root entry {
        report {"beats": len(heartbeat_log)};
    }
}
