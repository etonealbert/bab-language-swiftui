import SwiftUI

struct RadarPulseView: View {
    @State private var animate = false
    
    let ringCount = 3
    let baseColor: Color
    
    init(baseColor: Color = .blue) {
        self.baseColor = baseColor
    }
    
    var body: some View {
        ZStack {
            // Concentric pulse rings
            ForEach(0..<ringCount, id: \.self) { index in
                Circle()
                    .stroke(
                        baseColor.opacity(animate ? 0 : 0.5),
                        lineWidth: 2
                    )
                    .scaleEffect(animate ? 2.5 : 0.4)
                    .animation(
                        .easeOut(duration: 2.4)
                        .repeatForever(autoreverses: false)
                        .delay(Double(index) * 0.8),
                        value: animate
                    )
            }
            
            // Center dot
            Circle()
                .fill(
                    .radialGradient(
                        colors: [baseColor, baseColor.opacity(0.4)],
                        center: .center,
                        startRadius: 0,
                        endRadius: 28
                    )
                )
                .frame(width: 56, height: 56)
                .shadow(color: baseColor.opacity(0.5), radius: 12, x: 0, y: 0)
            
            Image(systemName: "antenna.radiowaves.left.and.right")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.white)
        }
        .frame(width: 200, height: 200)
        .onAppear { animate = true }
        .onDisappear { animate = false }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        RadarPulseView(baseColor: .cyan)
    }
}
