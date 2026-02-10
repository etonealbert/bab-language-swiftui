import SwiftUI

struct DialogBubble: View {
    let text: String
    let translation: String?
    let roleName: String
    let isUser: Bool
    let highlightedWordCount: Int
    let onWordLongPress: ((String, Int) -> Void)?
    
    @State private var isVisible = false
    
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
        var opacity = 0.0 // Starts invisible
        var verticalOffset = 20.0
    }
    
    private var words: [String] {
        text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
    }
    
    var body: some View {
        // 2. FIX: Use 'isVisible' as trigger
        KeyframeAnimator(initialValue: AnimationValues(), trigger: isVisible) { values in
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
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .strokeBorder(.white.opacity(0.2), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
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
        .onAppear {
            // 3. FIX: Trigger the animation when the view appears
            isVisible = true
        }
    }
    
    @ViewBuilder
    private var interactiveText: some View {
        if onWordLongPress != nil {
            // 4. FIX: Use FlowLayout (iOS 16+) or WrappingHStack logic
            // Standard HStack puts everything on one line.
            // This is a simple native Flow Layout implementation:
            FlowLayout(spacing: 4) {
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

// Add this Helper for Text Wrapping (Native iOS 16+ Style)
struct FlowLayout: Layout {
    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = arrangeSubviews(proposal: proposal, subviews: subviews)
        return rows.last?.maxY ?? .zero
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = arrangeSubviews(proposal: proposal, subviews: subviews)
        for row in rows {
            for element in row.elements {
                element.subview.place(at: CGPoint(x: bounds.minX + element.x, y: bounds.minY + row.y), proposal: proposal)
            }
        }
    }
    
    struct Row {
        var elements: [Element] = []
        var y: CGFloat = 0
        var height: CGFloat = 0
        var maxY: CGSize { CGSize(width: 0, height: y + height) }
    }
    
    struct Element {
        var subview: LayoutSubview
        var x: CGFloat
    }
    
    func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> [Row] {
        var rows: [Row] = []
        var currentRow = Row()
        var x: CGFloat = 0
        let maxWidth = proposal.width ?? .infinity
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && !currentRow.elements.isEmpty {
                currentRow.y = rows.last?.maxY.height ?? 0
                rows.append(currentRow)
                currentRow = Row()
                x = 0
            }
            currentRow.elements.append(Element(subview: subview, x: x))
            currentRow.height = max(currentRow.height, size.height)
            x += size.width + spacing
        }
        if !currentRow.elements.isEmpty {
            currentRow.y = rows.last?.maxY.height ?? 0
            rows.append(currentRow)
        }
        
        return rows
    }
}
