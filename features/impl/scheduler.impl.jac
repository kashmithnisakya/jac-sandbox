"""Bodies for `features/scheduler.sv.jac`."""

impl HeartbeatTick.go with Root entry {
    heartbeat_log.append("beat");
}

impl ReadHeartbeat.go with Root entry {
    report {"beats": len(heartbeat_log)};
}
