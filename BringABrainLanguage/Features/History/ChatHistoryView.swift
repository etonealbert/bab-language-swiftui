import SwiftUI
import SwiftData

struct ChatHistoryView: View {
    var body: some View {
        NavigationStack {
            HistorySessionList()
                .navigationTitle("History")
        }
    }
}

private struct HistorySessionList: View {
    @Query(
        filter: #Predicate<SDConversationSession> { $0.isComplete },
        sort: \.date,
        order: .reverse
    )
    private var sessions: [SDConversationSession]
    
    @State private var selectedSession: SDConversationSession?
    @EnvironmentObject var observer: SDKObserver
    
    var body: some View {
        Group {
            if sessions.isEmpty {
                ContentUnavailableView(
                    "No Sessions Yet",
                    systemImage: "clock.arrow.circlepath",
                    description: Text("Your completed conversations will appear here.")
                )
            } else {
                List {
                    ForEach(sessions) { session in
                        Button {
                            selectedSession = session
                        } label: {
                            HistoryRow(session: session)
                        }
                        .tint(.primary)
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            observer.deleteConversationSession(id: sessions[index].id)
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .sheet(item: $selectedSession) { session in
            SessionDetailView(session: session)
        }
    }
}

private struct HistoryRow: View {
    let session: SDConversationSession
    
    private var formattedDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: session.date, relativeTo: Date())
    }
    
    private var languageFlag: String {
        switch session.targetLanguage.lowercased() {
        case "spanish", "es": return "🇪🇸"
        case "french", "fr": return "🇫🇷"
        case "german", "de": return "🇩🇪"
        case "italian", "it": return "🇮🇹"
        case "portuguese", "pt": return "🇧🇷"
        case "japanese", "ja": return "🇯🇵"
        case "korean", "ko": return "🇰🇷"
        case "chinese", "zh": return "🇨🇳"
        default: return "🌐"
        }
    }
    
    var body: some View {
        HStack(spacing: 14) {
            Text(languageFlag)
                .font(.system(size: 32))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(session.scenarioTitle)
                    .font(.headline)
                
                HStack(spacing: 12) {
                    Label("\(session.durationMinutes)m", systemImage: "clock")
                    Label("\(session.messages.count) lines", systemImage: "bubble.left.and.bubble.right")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Text(formattedDate)
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
}

private struct SessionDetailView: View {
    let session: SDConversationSession
    
    @Query private var messages: [SDConversationMessage]
    
    init(session: SDConversationSession) {
        self.session = session
        let sessionId = session.id
        _messages = Query(
            filter: #Predicate<SDConversationMessage> { $0.sessionId == sessionId },
            sort: \.timestamp
        )
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label(session.targetLanguage.uppercased(), systemImage: "globe")
                        Label("\(session.durationMinutes)m", systemImage: "clock")
                        Label("\(messages.count) lines", systemImage: "text.bubble")
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.bottom)
                    
                    ForEach(messages) { message in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(message.role)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)
                            Text(message.text)
                                .font(.body)
                            if let translation = message.translation {
                                Text(translation)
                                    .font(.callout)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .padding()
            }
            .navigationTitle(session.scenarioTitle)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

extension SDConversationSession: @retroactive Identifiable {}

#Preview {
    ChatHistoryView()
}
