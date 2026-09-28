import Foundation

struct UsageSession: Codable, Identifiable, Equatable {
    let id: UUID
    let startedAt: Date
    var endedAt: Date?
}

struct UsageHistoryStore {
    static let retention: TimeInterval = 30 * 24 * 60 * 60
    private static let key = "usageSessions"

    let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func sessions(now: Date = .now) -> [UsageSession] {
        let saved = (defaults.data(forKey: Self.key))
            .flatMap { try? JSONDecoder().decode([UsageSession].self, from: $0) } ?? []
        let retained = saved.filter { $0.startedAt <= now && $0.startedAt >= now.addingTimeInterval(-Self.retention) }
        if retained != saved { save(retained) }
        return retained.sorted { $0.startedAt > $1.startedAt }
    }

    @discardableResult
    func start(now: Date = .now) -> UUID {
        let id = UUID()
        var entries = sessions(now: now)
        entries.insert(UsageSession(id: id, startedAt: now, endedAt: nil), at: 0)
        save(entries)
        return id
    }

    func end(_ id: UUID, now: Date = .now) {
        var entries = sessions(now: now)
        guard let index = entries.firstIndex(where: { $0.id == id && $0.endedAt == nil }) else { return }
        entries[index].endedAt = max(now, entries[index].startedAt)
        save(entries)
    }

    func endOpenSessions(startedAfter launchDate: Date, now: Date = .now) {
        var entries = sessions(now: now)
        for index in entries.indices where entries[index].endedAt == nil && entries[index].startedAt >= launchDate {
            entries[index].endedAt = max(now, entries[index].startedAt)
        }
        save(entries)
    }

    private func save(_ entries: [UsageSession]) {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        defaults.set(data, forKey: Self.key)
    }
}
