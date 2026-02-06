import SwiftUI

struct StatCard: View {
    let title: String
    let value: String
    var icon: String? = nil
    var color: Color = .blue
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                Spacer()
                if let icon = icon {
                    Image(systemName: icon)
                        .foregroundStyle(color)
                }
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .contentTransition(.numericText())
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(color.opacity(0.2), lineWidth: 1)
        )
    }
}

#Preview {
    HStack {
        StatCard(title: "Total Words", value: "1,204", icon: "text.book.closed", color: .purple)
        StatCard(title: "Due Now", value: "15", icon: "clock", color: .orange)
    }
    .padding()
}
