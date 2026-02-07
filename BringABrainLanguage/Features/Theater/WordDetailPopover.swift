import SwiftUI

struct LocalWordTranslation {
    let translatedWord: String
    let partOfSpeech: String?
}

struct WordDetailPopover: View {
    let word: String
    let translation: LocalWordTranslation?
    let isLoading: Bool
    let isInVocabulary: Bool
    let onAddToVocabulary: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(word)
                .font(.title2.bold())
            
            if isLoading {
                ProgressView()
            } else if let translation = translation {
                Text(translation.translatedWord)
                    .font(.headline)
                    .foregroundStyle(.secondary)
                
                if let pos = translation.partOfSpeech {
                    Text(pos)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .italic()
                }
                
                Divider()
                
                if isInVocabulary {
                    Label("Already in vocabulary", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                } else {
                    Button(action: onAddToVocabulary) {
                        Label("Add to Vocabulary", systemImage: "plus.circle.fill")
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                Text("Translation unavailable")
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(minWidth: 200)
    }
}
