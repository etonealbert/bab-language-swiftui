import SwiftUI
import SwiftData

struct DialogLibraryView: View {
    @Query(sort: \SDSavedSession.playedAt, order: .reverse) private var sessions: [SDSavedSession]
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        List {
            if sessions.isEmpty {
                ContentUnavailableView(
                    "No Saved Dialogs",
                    systemImage: "bubble.left.and.bubble.right",
                    description: Text("Complete a scenario to save your conversation history here.")
                )
                .listRowSeparator(.hidden)
            } else {
                ForEach(sessions) { session in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(session.scenarioName)
                            .font(.headline)
                        
                        HStack {
                            Text(session.playedAt, style: .date)
                            Text("•")
                            Text("\(session.durationMinutes) min")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                .onDelete(perform: deleteSessions)
            }
        }
        .listStyle(.plain)
    }
    
    private func deleteSessions(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(sessions[index])
            }
        }
    }
}
