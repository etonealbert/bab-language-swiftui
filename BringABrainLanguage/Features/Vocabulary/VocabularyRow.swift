import SwiftUI

struct VocabularyRow: View {
    let entry: SDVocabularyEntry
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.word)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(entry.translation)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 6) {
                // Mastery Dots
                HStack(spacing: 3) {
                    ForEach(0..<5) { index in
                        Circle()
                            .fill(index < entry.masteryLevel ? Color.green : Color.secondary.opacity(0.2))
                            .frame(width: 6, height: 6)
                    }
                }
                
                // Review Status
                if entry.nextReviewAt <= Date() {
                    Text("Review Now")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(.orange)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(0.1))
                        .clipShape(Capsule())
                } else {
                    Text(reviewDateString(for: entry.nextReviewAt))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle()) // Make full row tappable
    }
    
    private func reviewDateString(for date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    let entry1 = SDVocabularyEntry(word: "Hola", translation: "Hello", language: "es")
    entry1.masteryLevel = 3
    entry1.nextReviewAt = Date().addingTimeInterval(86400) // Tomorrow
    
    let entry2 = SDVocabularyEntry(word: "Gato", translation: "Cat", language: "es")
    entry2.masteryLevel = 5
    entry2.nextReviewAt = Date().addingTimeInterval(-3600) // 1 hour ago (Due)
    
    return List {
        VocabularyRow(entry: entry1)
        VocabularyRow(entry: entry2)
    }
}
