import SwiftUI

struct DialogBubble: View {
    let text: String
    let roleName: String
    let isUser: Bool
    
    struct AnimationValues {
        var scale = 0.8
        var opacity = 0.0
        var verticalOffset = 20.0
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
                    
                    Text(text)
                        .font(.body)
                        .padding(12)
                        .background(
                            isUser 
                                ? AnyShapeStyle(.blue.gradient) 
                                : AnyShapeStyle(.thinMaterial)
                        )
                        .foregroundStyle(isUser ? .white : .primary)
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
}

#Preview {
    VStack {
        DialogBubble(text: "Hello! How can I help you today?", roleName: "Barista", isUser: false)
        DialogBubble(text: "I'd like a latte, please.", roleName: "You", isUser: true)
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}
