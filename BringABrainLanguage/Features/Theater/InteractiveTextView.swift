import SwiftUI

struct InteractiveTextView: View {
    let text: String
    let highlightedWordCount: Int
    let onWordLongPress: (String, Int) -> Void
    
    private var words: [String] {
        text.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
    }
    
    var body: some View {
        WrappingHStack(alignment: .leading, spacing: 4) {
            ForEach(Array(words.enumerated()), id: \.offset) { index, word in
                WordView(
                    word: word,
                    isHighlighted: index < highlightedWordCount,
                    onLongPress: {
                        onWordLongPress(word, index)
                    }
                )
            }
        }
    }
}

struct WordView: View {
    let word: String
    let isHighlighted: Bool
    let onLongPress: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Text(word)
            .foregroundStyle(isHighlighted ? .green : .primary)
            .fontWeight(isHighlighted ? .semibold : .regular)
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
            .onLongPressGesture(
                minimumDuration: 0.3,
                pressing: { pressing in
                    isPressed = pressing
                },
                perform: onLongPress
            )
    }
}

struct WrappingHStack<Content: View>: View {
    let alignment: HorizontalAlignment
    let spacing: CGFloat
    @ViewBuilder let content: () -> Content
    
    init(
        alignment: HorizontalAlignment = .leading,
        spacing: CGFloat = 8,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.alignment = alignment
        self.spacing = spacing
        self.content = content
    }
    
    var body: some View {
        GeometryReader { geometry in
            self.generateContent(in: geometry)
        }
    }
    
    private func generateContent(in geometry: GeometryProxy) -> some View {
        var width = CGFloat.zero
        var height = CGFloat.zero
        
        return ZStack(alignment: .topLeading) {
            content()
                .alignmentGuide(.leading) { dimension in
                    if abs(width - dimension.width) > geometry.size.width {
                        width = 0
                        height -= dimension.height + spacing
                    }
                    let result = width
                    width -= dimension.width + spacing
                    return result
                }
                .alignmentGuide(.top) { _ in
                    let result = height
                    return result
                }
        }
    }
}
