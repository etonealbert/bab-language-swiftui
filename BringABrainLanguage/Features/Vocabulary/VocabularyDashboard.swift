import SwiftUI
import SwiftData

struct VocabularyDashboard: View {
    @EnvironmentObject var observer: SDKObserver
    @Query(sort: \SDVocabularyEntry.nextReviewAt) private var allWords: [SDVocabularyEntry]
    
    var dueWords: [SDVocabularyEntry] {
        allWords.filter { $0.nextReviewAt <= Date() }
    }
    
    var totalWordsCount: Int {
        if let total = observer.vocabularyStats?.total {
            return Int(total)
        }
        return allWords.count
    }
    
    var dueCount: Int {
        if let due = observer.vocabularyStats?.dueCount {
            return Int(due)
        }
        return dueWords.count
    }
    
    var masteredCount: Int {
        if let mastered = observer.vocabularyStats?.masteredCount {
            return Int(mastered)
        }
        return allWords.filter { $0.masteryLevel >= 5 }.count
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                statsSection
                
                if dueCount > 0 {
                    Button(action: startReview) {
                        HStack {
                            Image(systemName: "play.fill")
                            Text("Review \(dueCount) Words")
                                .fontWeight(.bold)
                        }
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .clipShape(Capsule())
                        .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                    .padding(.horizontal)
                    .symbolEffect(.bounce, value: dueCount)
                }
                
                if allWords.isEmpty {
                    emptyState
                } else {
                    wordsList
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Vocabulary")
        .background(Color(.systemGroupedBackground))
    }
    
    private var statsSection: some View {
        HStack(spacing: 12) {
            StatCard(
                title: "Total",
                value: "\(totalWordsCount)",
                icon: "text.book.closed",
                color: .blue
            )
            
            StatCard(
                title: "Due",
                value: "\(dueCount)",
                icon: "clock",
                color: .orange
            )
            .overlay(alignment: .topTrailing) {
                if dueCount > 0 {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                        .offset(x: -4, y: 4)
                        .symbolEffect(.pulse)
                }
            }
            
            StatCard(
                title: "Mastered",
                value: "\(masteredCount)",
                icon: "star.fill",
                color: .yellow
            )
        }
        .padding(.horizontal)
    }
    
    private var wordsList: some View {
        LazyVStack(alignment: .leading, spacing: 16) {
            ForEach(0...5, id: \.self) { level in
                let wordsInLevel = allWords.filter { $0.masteryLevel == level }
                
                if !wordsInLevel.isEmpty {
                    Section {
                        ForEach(wordsInLevel) { word in
                            VocabularyRow(entry: word)
                            Divider()
                        }
                    } header: {
                        HStack {
                            Text(levelLabel(for: level))
                                .font(.headline)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("\(wordsInLevel.count)")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.secondary.opacity(0.1))
                                .clipShape(Capsule())
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                    }
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "books.vertical")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("No words yet")
                .font(.title3)
                .fontWeight(.medium)
            Text("Start a conversation to learn new words.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
        .frame(maxWidth: .infinity)
    }
    
    private func levelLabel(for level: Int) -> String {
        switch level {
        case 0: return "New"
        case 5: return "Mastered"
        default: return "Level \(level)"
        }
    }
    
    private func startReview() {
    }
}

#Preview {
    VocabularyDashboard()
        .modelContainer(for: SDVocabularyEntry.self, inMemory: true)
}
