import SwiftUI

struct StatPill: View {
    let icon: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption.bold())
                .foregroundStyle(color)
                .symbolEffect(.breathe, isActive: icon.contains("flame"))
            
            Text(value)
                .font(.caption.bold())
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background {
            Capsule()
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
        .overlay {
            Capsule()
                .strokeBorder(color.opacity(0.3), lineWidth: 1)
        }
    }
}
