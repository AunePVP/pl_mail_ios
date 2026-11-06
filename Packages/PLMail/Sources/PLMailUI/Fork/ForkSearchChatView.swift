#if os(iOS)

// FORK (FORK.md 5): the web's AI search chat (server FORK.md 20) as a sheet.

import JMAPKit
import PLMailCore
import SwiftUI

/// A conversation about the mailbox: the search text is the first question,
/// follow-ups ("und zurück?") keep the server's conversation id so the model
/// knows what was asked before. Each turn comes back whole after some seconds
/// — JMAP has no streaming — so a turn in flight shows a spinner.
struct ForkSearchChatView: View {
    let firstMessage: String
    let sync: MailSyncService
    let onOpen: (ForkThreadPointer) -> Void

    private struct Turn: Identifiable {
        let id = UUID()
        var question: String
        var answer: String?
        var important: [ForkThreadPointer] = []
        var failed = false
    }

    @Environment(\.dismiss) private var dismiss
    @State private var turns: [Turn] = []
    @State private var conversation: String?
    @State private var draft = ""
    @State private var isBusy = false

    var body: some View {
        NavigationStack {
            ScrollViewReader { scroller in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 16) {
                        ForEach(turns) { turn in
                            turnView(turn).id(turn.id)
                        }
                    }
                    .padding(16)
                }
                .onChange(of: turns.count) { _, _ in
                    if let last = turns.last {
                        withAnimation { scroller.scrollTo(last.id, anchor: .bottom) }
                    }
                }
            }
            .safeAreaInset(edge: .bottom) { composer }
            .navigationTitle(ForkSearchInsightView.text(de: "KI-Suche", en: "AI search"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(ForkSearchInsightView.text(de: "Fertig", en: "Done")) { dismiss() }
                }
            }
        }
        .task {
            guard turns.isEmpty else { return }
            await send(firstMessage)
        }
    }

    private func turnView(_ turn: Turn) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(verbatim: turn.question)
                .font(.subheadline.weight(.semibold))
                .padding(10)
                .background(.tint.opacity(0.12), in: .rect(cornerRadius: 10))
                .frame(maxWidth: .infinity, alignment: .trailing)

            if let answer = turn.answer {
                Text(verbatim: answer).font(.body).textSelection(.enabled)

                ForEach(turn.important, id: \.threadId) { pointer in
                    Button {
                        onOpen(pointer)
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "envelope").font(.caption)
                            if let date = pointer.receivedAt {
                                Text(date.date, format: .dateTime.day().month(.abbreviated))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Text(verbatim: pointer.subject.flatMap { $0.isEmpty ? nil : $0 } ?? "—")
                                .font(.caption)
                                .lineLimit(1)
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            } else if turn.failed {
                Text(Self.failedText)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                HStack(spacing: 6) {
                    ProgressView().controlSize(.small)
                    Text(Self.busyText)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private static var failedText: String {
        ForkSearchInsightView.text(
            de: "Die KI konnte gerade nicht antworten.", en: "The AI could not answer just now.")
    }

    private static var busyText: String {
        ForkSearchInsightView.text(de: "Sucht und denkt nach …", en: "Searching and thinking …")
    }

    private var composer: some View {
        HStack(spacing: 8) {
            TextField(
                ForkSearchInsightView.text(de: "Rückfrage …", en: "Follow-up …"), text: $draft,
                axis: .vertical
            )
            .textFieldStyle(.roundedBorder)
            .lineLimit(1...4)
            .submitLabel(.send)
            .onSubmit { submit() }

            Button {
                submit()
            } label: {
                Image(systemName: "arrow.up.circle.fill").font(.title2)
            }
            .disabled(isBusy || draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.bar)
    }

    private func submit() {
        let message = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard message.isEmpty == false, isBusy == false else { return }
        draft = ""
        Task { await send(message) }
    }

    private func send(_ message: String) async {
        let question = message.trimmingCharacters(in: .whitespacesAndNewlines)
        guard question.isEmpty == false else { return }

        isBusy = true
        defer { isBusy = false }

        turns.append(Turn(question: question))
        let index = turns.count - 1

        let client = sync.jmapClient

        do {
            var builder = RequestBuilder(session: try await client.session())
            let call = builder.add(ForkSearchChat(message: question, conversation: conversation))
            let results = try await client.send(builder)

            if results.failure(of: call) != nil {
                turns[index].failed = true
                return
            }

            let result = try results.result(of: call)
            conversation = result.conversation ?? conversation

            if let answer = result.answer, result.error == false {
                turns[index].answer = answer
                turns[index].important = result.important
            } else {
                turns[index].failed = true
            }
        } catch {
            turns[index].failed = true
        }
    }
}

#endif
