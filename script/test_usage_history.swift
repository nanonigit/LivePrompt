import Foundation

@main
struct UsageHistoryChecks {
    static func main() {
        let suite = "LivePromptUsageHistoryChecks.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suite) else { fatalError("Cannot create defaults suite") }
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = UsageHistoryStore(defaults: defaults)
        let now = Date(timeIntervalSince1970: 1_800_000_000)

        let expired = store.start(now: now.addingTimeInterval(-UsageHistoryStore.retention - 1))
        precondition(store.sessions(now: now).isEmpty, "Expired entries must be removed")

        let interrupted = store.start(now: now.addingTimeInterval(-3_600))
        let current = store.start(now: now.addingTimeInterval(-10))
        store.endOpenSessions(startedAfter: now.addingTimeInterval(-60), now: now)
        let sessions = store.sessions(now: now)
        precondition(sessions.count == 2)
        precondition(sessions.first(where: { $0.id == interrupted })?.endedAt == nil)
        precondition(sessions.first(where: { $0.id == current })?.endedAt == now)
        precondition(sessions.first(where: { $0.id == expired }) == nil)

        let completed = store.start(now: now.addingTimeInterval(1))
        store.end(completed, now: now.addingTimeInterval(126))
        precondition(store.sessions(now: now.addingTimeInterval(126)).first(where: { $0.id == completed })?.endedAt == now.addingTimeInterval(126))
        print("Usage history checks passed")
    }
}
