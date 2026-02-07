import SwiftUI

struct AudioWaveformView: View {
    let level: Float
    private let barCount = 5
    
    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<barCount, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(.tint)
                    .frame(width: 4)
                    .frame(height: barHeight(for: index))
                    .animation(.easeInOut(duration: 0.1), value: level)
            }
        }
    }
    
    private func barHeight(for index: Int) -> CGFloat {
        let baseHeight: CGFloat = 8
        let maxHeight: CGFloat = 24
        let normalizedLevel = CGFloat(level)
        let variation = sin(Double(index) * .pi / Double(barCount - 1))
        return baseHeight + (maxHeight - baseHeight) * normalizedLevel * CGFloat(variation)
    }
}
