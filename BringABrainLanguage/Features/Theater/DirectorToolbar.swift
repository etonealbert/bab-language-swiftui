import SwiftUI

struct DirectorToolbar: View {
    var onHint: () -> Void
    var onReplay: () -> Void
    var onEnd: () -> Void
    
    @State private var hintTrigger = 0
    @State private var replayTrigger = 0
    @State private var endTrigger = false
    
    var body: some View {
        HStack(spacing: 40) {
            Button {
                hintTrigger += 1
                onHint()
            } label: {
                VStack(spacing: 6) {
                    Image(systemName: "lightbulb.max.fill")
                        .font(.system(size: 24))
                        .symbolEffect(.wiggle, value: hintTrigger)
                        .foregroundStyle(.yellow)
                    
                    Text("Hint")
                        .font(.caption2.bold())
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)
            
            Button {
                replayTrigger += 1
                onReplay()
            } label: {
                VStack(spacing: 6) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 24))
                        .symbolEffect(.bounce, value: replayTrigger)
                        .foregroundStyle(.blue)
                    
                    Text("Replay")
                        .font(.caption2.bold())
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)
            
            Button {
                endTrigger.toggle()
                onEnd()
            } label: {
                VStack(spacing: 6) {
                    Image(systemName: "stop.circle.fill")
                        .font(.system(size: 24))
                        .symbolEffect(.breathe, isActive: endTrigger)
                        .foregroundStyle(.red)
                    
                    Text("End")
                        .font(.caption2.bold())
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 30)
        .padding(.vertical, 16)
        .background(.regularMaterial)
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.1), radius: 15, x: 0, y: 5)
        .padding(.bottom)
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.1).ignoresSafeArea()
        VStack {
            Spacer()
            DirectorToolbar(onHint: {}, onReplay: {}, onEnd: {})
        }
    }
}
