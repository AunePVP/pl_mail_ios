#if os(iOS)

// FORK (FORK.md 4): the Unsubscribe button of the web reader (server FORK.md 13),
// drawn under an expanded message when the server fork names a target.

import JMAPKit
import SwiftUI

/// What a message card needs to ask the server fork about itself.
///
/// Handed down through the environment rather than as an argument, so the
/// original `MessageView` gains one line and no new parameter.
public struct ForkReaderContext: Sendable {
    public var client: JMAPClient
    public var accountID: AccountID

    public init(client: JMAPClient, accountID: AccountID) {
        self.client = client
        self.accountID = accountID
    }
}

extension EnvironmentValues {
    @Entry public var forkReaderContext: ForkReaderContext?
}

/// Remembers answers for the session, so scrolling a thread or reopening it
/// does not ask again. `nil` inside means "asked, nothing there".
actor ForkUnsubscribeCache {
    static let shared = ForkUnsubscribeCache()

    private var targets: [String: ForkUnsubscribeTarget?] = [:]
    private var unsupported = false

    func target(for emailID: String, in context: ForkReaderContext) async -> ForkUnsubscribeTarget? {
        let key = "\(context.accountID.rawValue)#\(emailID)"

        if let known = targets[key] { return known }
        if unsupported { return nil }

        do {
            var builder = RequestBuilder(session: try await context.client.session())
            let call = builder.add(ForkUnsubscribeGet(accountID: context.accountID, ids: [emailID]))
            let results = try await context.client.send(builder)

            if results.failure(of: call) != nil {
                // A server without the fork: stop asking for this session.
                unsupported = true
                return nil
            }

            let found = try results.result(of: call).list.first { $0.id == emailID }
            targets[key] = .some(found)

            return found
        } catch {
            // Offline or a hiccup: leave it unanswered, so the next open asks again.
            return nil
        }
    }
}

/// A small "Unsubscribe" chip; nothing at all when there is no target.
struct ForkUnsubscribeButton: View {
    let emailID: String

    @Environment(\.forkReaderContext) private var context
    @Environment(\.openURL) private var openURL
    @State private var target: ForkUnsubscribeTarget?

    var body: some View {
        Group {
            if let target, let url = Self.url(for: target) {
                Button {
                    openURL(url)
                } label: {
                    Label(Self.label, systemImage: "envelope.badge.shield.half.filled")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .accessibilityHint(Text(Self.hint(for: target)))
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .task(id: emailID) {
            guard let context else { return }

            target = await ForkUnsubscribeCache.shared.target(for: emailID, in: context)
        }
    }

    /// Only `http(s)` and `mailto:` — the server already filters, this is the
    /// second lock on the same door. A mailto opens the system's mail handler.
    static func url(for target: ForkUnsubscribeTarget) -> URL? {
        if let link = target.url, let url = URL(string: link),
            ["http", "https"].contains(url.scheme?.lowercased() ?? "")
        {
            return url
        }

        if let address = target.mailto,
            let encoded = address.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)
        {
            return URL(string: "mailto:\(encoded)")
        }

        return nil
    }

    private static var isGerman: Bool {
        Locale.preferredLanguages.first?.hasPrefix("de") == true
    }

    private static var label: String { isGerman ? "Abmelden" : "Unsubscribe" }

    private static func hint(for target: ForkUnsubscribeTarget) -> String {
        switch (target.fromBody == true, target.mailto != nil, isGerman) {
        case (true, _, true): "Link aus dem Text der Mail"
        case (true, _, false): "Link found in the message text"
        case (_, true, true): "Schreibt eine Mail an die Abmeldeadresse"
        case (_, true, false): "Writes to the unsubscribe address"
        case (_, false, true): "Öffnet die Abmeldeseite des Absenders"
        case (_, false, false): "Opens the sender's unsubscribe page"
        }
    }
}

#endif
