"""Bodies for `features/scheduler.sv.jac`."""

impl HeartbeatTick.go with Root entry {
    heartbeat_log.append("beat");
    print(f"""HeartbeatTick fired, log length: {len(heartbeat_log)}""");
}

impl ReadHeartbeat.go with Root entry {
    report {"beats": len(heartbeat_log)};
}
