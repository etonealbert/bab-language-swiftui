import SwiftUI

struct DialogBubble: View {
    let text: String
    let translation: String?
    let roleName: String
    let isUser: Bool
    let highlightedWordCount: Int
    let onWordLongPress: ((String, Int) -> Void)?
    
    init(
        text: String,
        translation: String? = nil,
        roleName: String,
        isUser: Bool,
        highlightedWordCount: Int = 0,
        onWordLongPress: ((String, Int) -> Void)? = nil
    ) {
        self.text = text
        self.translation = translation
        self.roleName = roleName
        self.isUser = isUser
        self.highlightedWordCount = highlightedWordCount
        self.onWordLongPress = onWordLongPress
    }
    
    struct AnimationValues {
        var scale = 0.8
        var opacity = 0.0
        var verticalOffset = 20.0
    }
    
    private var words: [String] {
        text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
    }
    
    var body: some View {
        KeyframeAnimator(initialValue: AnimationValues(), trigger: true) { values in
            HStack(alignment: .bottom, spacing: 12) {
                if isUser { Spacer() }
                
                VStack(alignment: isUser ? .trailing : .leading, spacing: 4) {
                    if !isUser {
                        Text(roleName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.leading, 4)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        interactiveText
                        
                        if let translation = translation {
                            Text(translation)
                                .font(.caption)
                                .foregroundStyle(isUser ? .white.opacity(0.8) : .secondary)
                        }
                    }
                    .padding(12)
                    .background(
                        isUser 
                            ? AnyShapeStyle(.blue.gradient) 
                            : AnyShapeStyle(.thinMaterial)
                    )
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: 20, 
                            style: .continuous
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .strokeBorder(.white.opacity(0.2), lineWidth: 1)
                    )
                    .shadow(
                        color: .black.opacity(0.05),
                        radius: 5,
                        x: 0,
                        y: 2
                    )
                }
                
                if !isUser { Spacer() }
            }
            .scaleEffect(values.scale, anchor: isUser ? .bottomTrailing : .bottomLeading)
            .opacity(values.opacity)
            .offset(y: values.verticalOffset)
        } keyframes: { _ in
            KeyframeTrack(\.scale) {
                SpringKeyframe(1.05, duration: 0.2, spring: .bouncy(duration: 0.3, extraBounce: 0.1))
                SpringKeyframe(1.0, duration: 0.15)
            }
            
            KeyframeTrack(\.opacity) {
                LinearKeyframe(1.0, duration: 0.2)
            }
            
            KeyframeTrack(\.verticalOffset) {
                SpringKeyframe(-5.0, duration: 0.2, spring: .bouncy)
                SpringKeyframe(0.0, duration: 0.15)
            }
        }
    }
    
    @ViewBuilder
    private var interactiveText: some View {
        if onWordLongPress != nil {
            HStack(spacing: 4) {
                ForEach(Array(words.enumerated()), id: \.offset) { index, word in
                    Text(word)
                        .font(.body)
                        .foregroundStyle(wordColor(for: index))
                        .fontWeight(index < highlightedWordCount ? .semibold : .regular)
                        .onLongPressGesture {
                            onWordLongPress?(word, index)
                        }
                }
            }
        } else {
            Text(text)
                .font(.body)
                .foregroundStyle(isUser ? .white : .primary)
        }
    }
    
    private func wordColor(for index: Int) -> Color {
        if index < highlightedWordCount {
            return .green
        }
        return isUser ? .white : .primary
    }
}

#Preview {
    VStack {
        DialogBubble(
            text: "¡Hola! ¿Cómo puedo ayudarte hoy?",
            translation: "Hello! How can I help you today?",
            roleName: "Barista",
            isUser: false,
            highlightedWordCount: 2
        )
        DialogBubble(
            text: "Me gustaría un café con leche, por favor.",
            translation: "I would like a latte, please.",
            roleName: "You",
            isUser: true,
            highlightedWordCount: 4
        )
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}
