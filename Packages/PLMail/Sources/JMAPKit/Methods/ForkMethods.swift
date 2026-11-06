import Foundation

// FORK (FORK.md 4): methods only the AunePVP/pl_mail server fork answers.
//
// Both go under `Capability.mail`, like `Contact/autocomplete`: the server does
// not gate dispatch on a method's capability, and declaring a URN an older
// server does not know would fail the whole request. A server without the
// methods answers `unknownMethod` for that call alone, and the caller then
// simply draws nothing.

/// Where to unsubscribe from one message.
public struct ForkUnsubscribeTarget: Decodable, Sendable, Hashable {
    public var id: String
    /// A web page of the sender's. Opened, never requested by the app itself.
    public var url: String?
    /// An address to write to instead.
    public var mailto: String?
    /// The link was found in the mail's text rather than its `List-Unsubscribe`
    /// header — a good guess, but a guess.
    public var fromBody: Bool?
}

/// `ForkUnsubscribe/get` — the web reader's Unsubscribe button, per message.
public struct ForkUnsubscribeGet: JMAPMethod {
    public static let name = "ForkUnsubscribe/get"
    public static let capability = Capability.mail

    public struct Arguments: Encodable, Sendable {
        public var accountID: AccountID
        public var ids: [String]

        private enum CodingKeys: String, CodingKey {
            case accountID = "accountId"
            case ids
        }
    }

    public struct Result: Decodable, Sendable {
        public var list: [ForkUnsubscribeTarget]
    }

    public var arguments: Arguments

    public init(accountID: AccountID, ids: [String]) {
        arguments = Arguments(accountID: accountID, ids: ids)
    }
}

/// A conversation the server pointed at, with what is needed to open it.
public struct ForkThreadPointer: Decodable, Sendable, Hashable {
    public var threadId: String
    public var accountId: String?
    public var emailId: String?
    public var subject: String?
    public var receivedAt: UTCDate?
}

/// One upcoming event a search named.
public struct ForkSearchTrip: Decodable, Sendable, Hashable {
    public struct Mail: Decodable, Sendable, Hashable {
        public var emailId: String
        public var threadId: String?
        public var accountId: String?
        public var subject: String?
        public var from: String?
        public var receivedAt: UTCDate?
    }

    public var title: String?
    public var location: String?
    /// ISO 8601 with offset.
    public var start: String?
    public var end: String?
    public var isAllDay: Bool
    public var timeZone: String?
    public var isOffer: Bool
    public var emails: [Mail]
}

/// The chat model's short answer over the hits.
public struct ForkSearchAnswer: Decodable, Sendable, Hashable {
    public struct Group: Decodable, Sendable, Hashable {
        public var title: String
        public var threads: [ForkThreadPointer]
    }

    public var text: String
    public var important: [ForkThreadPointer]
    public var groups: [Group]
}

/// `ForkSearch/insight` — the panels the web search draws above its results:
/// the reranked best hits, upcoming events, and a short answer.
public struct ForkSearchInsight: JMAPMethod {
    public static let name = "ForkSearch/insight"
    public static let capability = Capability.mail

    public enum Part: String, Encodable, Sendable {
        case best, trips, answer
    }

    public struct Arguments: Encodable, Sendable {
        public var query: String
        public var parts: [Part]
    }

    public struct Result: Decodable, Sendable {
        public var best: [ForkThreadPointer]?
        public var trips: [ForkSearchTrip]?
        public var answer: ForkSearchAnswer?
    }

    public var arguments: Arguments

    public init(query: String, parts: [Part]) {
        arguments = Arguments(query: query, parts: parts)
    }
}
