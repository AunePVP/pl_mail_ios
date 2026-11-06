#if os(iOS)

// FORK (FORK.md 5): the web search's panels above the results (server FORK.md
// 16 and 18) — best hits by meaning, upcoming events, and a short answer.

import JMAPKit
import PLMailCore
import SwiftUI

/// Draws whatever the server fork answers for the settled query, each part as
/// it arrives: events and best hits first (a query and the reranker, a second
/// or so), the chat model's answer when it is done (several seconds). Nothing
/// at all on a server without the fork, offline, or for a query that is only
/// operators.
struct ForkSearchInsightView: View {
    let raw: String
    let sync: MailSyncService
    @Binding var selection: ThreadRef?

    @State private var best: [ForkThreadPointer] = []
    @State private var trips: [ForkSearchTrip] = []
    @State private var answer: ForkSearchAnswer?
    @State private var isAnswering = false
    @State private var isExpanded = true

    private var hasContent: Bool {
        best.isEmpty == false || trips.isEmpty == false || answer != nil || isAnswering
    }

    var body: some View {
        Group {
            if hasContent {
                DisclosureGroup(isExpanded: $isExpanded) {
                    VStack(alignment: .leading, spacing: 10) {
                        if trips.isEmpty == false { tripsPanel }
                        if best.isEmpty == false { bestPanel }
                        if let answer { answerPanel(answer) } else if isAnswering { answering }
                    }
                    .padding(.top, 6)
                } label: {
                    Label(Self.text(de: "KI-Suche", en: "AI search"), systemImage: "sparkles")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tint)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
        }
        .task(id: raw) { await load() }
    }

    // MARK: - Loading

    private func load() async {
        best = []
        trips = []
        answer = nil
        isAnswering = false

        let query = raw.trimmingCharacters(in: .whitespacesAndNewlines)

        guard query.isEmpty == false, ForkSearchSupport.shared.isKnownUnsupported == false else {
            return
        }

        // Fast parts first, the answer after, so the panel never waits on the model.
        if let quick = await Self.ask(sync.jmapClient, query: query, parts: [.trips, .best]) {
            guard Task.isCancelled == false else { return }
            trips = quick.trips ?? []
            best = quick.best ?? []
        } else {
            return
        }

        isAnswering = true
        let slow = await Self.ask(sync.jmapClient, query: query, parts: [.answer])
        guard Task.isCancelled == false else { return }
        answer = slow?.answer
        isAnswering = false
    }

    private static func ask(
        _ client: JMAPClient, query: String, parts: [ForkSearchInsight.Part]
    ) async -> ForkSearchInsight.Result? {
        do {
            var builder = RequestBuilder(session: try await client.session())
            let call = builder.add(ForkSearchInsight(query: query, parts: parts))
            let results = try await client.send(builder)

            if results.failure(of: call) != nil {
                ForkSearchSupport.shared.markUnsupported()
                return nil
            }

            return try results.result(of: call)
        } catch {
            return nil
        }
    }

    // MARK: - Panels

    private var tripsPanel: some View {
        VStack(alignment: .leading, spacing: 4) {
            heading(Self.text(de: "Termine dazu", en: "Upcoming"), systemImage: "calendar")

            ForEach(Array(trips.enumerated()), id: \.offset) { _, trip in
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(trip.title ?? "—").font(.subheadline.weight(.medium))
                        if trip.isOffer {
                            Text(Self.text(de: "Vorschlag", en: "Suggested"))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Text(Self.when(trip)).font(.caption).foregroundStyle(.secondary)

                    ForEach(trip.emails, id: \.emailId) { mail in
                        if let threadID = mail.threadId {
                            link(
                                subject: mail.subject, date: mail.receivedAt,
                                threadID: threadID, accountID: mail.accountId)
                        }
                    }
                }
            }
        }
    }

    private var bestPanel: some View {
        VStack(alignment: .leading, spacing: 4) {
            heading(Self.text(de: "Beste Treffer", en: "Best matches"), systemImage: "star")

            ForEach(best, id: \.threadId) { pointer in
                link(pointer)
            }
        }
    }

    private func answerPanel(_ answer: ForkSearchAnswer) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            heading(Self.text(de: "Kurz gesagt", en: "In short"), systemImage: "wand.and.stars")

            if answer.text.isEmpty == false {
                Text(answer.text).font(.subheadline)
            }

            ForEach(answer.important, id: \.threadId) { pointer in
                link(pointer)
            }

            ForEach(Array(answer.groups.enumerated()), id: \.offset) { _, group in
                DisclosureGroup {
                    ForEach(group.threads, id: \.threadId) { pointer in
                        link(pointer)
                    }
                } label: {
                    Text(verbatim: "\(group.title) · \(group.threads.count)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var answering: some View {
        HStack(spacing: 6) {
            ProgressView().controlSize(.mini)
            Text(Self.text(de: "KI fasst zusammen …", en: "Summarising …"))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func heading(_ title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
    }

    private func link(_ pointer: ForkThreadPointer) -> some View {
        link(
            subject: pointer.subject, date: pointer.receivedAt,
            threadID: pointer.threadId, accountID: pointer.accountId)
    }

    private func link(subject: String?, date: UTCDate?, threadID: String, accountID: String?)
        -> some View
    {
        Button {
            open(threadID: threadID, accountID: accountID, subject: subject ?? "")
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "arrow.right").font(.caption2).foregroundStyle(.tint)
                if let date {
                    Text(date.date, format: .dateTime.day().month(.abbreviated))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Text(subject.flatMap { $0.isEmpty ? nil : $0 } ?? "—")
                    .font(.caption)
                    .lineLimit(1)
                    .foregroundStyle(.primary)
            }
        }
        .buttonStyle(.plain)
    }

    private func open(threadID: String, accountID: String?, subject: String) {
        guard
            let account = sync.accounts.first(where: { $0.accountID.rawValue == accountID })
                ?? (sync.accounts.count == 1 ? sync.accounts.first : nil)
        else { return }

        selection = ThreadRef(accountKey: account.accountKey, threadID: threadID, subject: subject)
    }

    // MARK: - Text

    private static var isGerman: Bool {
        Locale.preferredLanguages.first?.hasPrefix("de") == true
    }

    static func text(de: String, en: String) -> String { isGerman ? de : en }

    /// The event's time in the reader's own zone; an all-day event by date alone.
    static func when(_ trip: ForkSearchTrip) -> String {
        guard let start = trip.start.flatMap(parse) else { return "" }

        if trip.isAllDay {
            return start.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated))
        }

        return start.formatted(
            .dateTime.weekday(.abbreviated).day().month(.abbreviated).hour().minute())
    }

    private static func parse(_ value: String) -> Date? {
        try? Date(value, strategy: .iso8601)
    }
}

/// Remembers that the server has no fork methods, so a search does not keep
/// asking a stock plMail every keystroke.
@MainActor
final class ForkSearchSupport {
    static let shared = ForkSearchSupport()

    private(set) var isKnownUnsupported = false

    func markUnsupported() {
        isKnownUnsupported = true
    }
}

#endif
