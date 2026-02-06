import SwiftUI

struct SettingsRow: View {
    let icon: String
    let title: String
    let value: String?
    let color: Color
    
    init(icon: String, title: String, value: String? = nil, color: Color = .blue) {
        self.icon = icon
        self.title = title
        self.value = value
        self.color = color
    }
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(color)
                    .frame(width: 30, height: 30)
                
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
            }
            
            Text(title)
                .font(.body)
                .foregroundColor(.primary)
            
            Spacer()
            
            if let value = value {
                Text(value)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    List {
        SettingsRow(icon: "star.fill", title: "Rate App", color: .yellow)
        SettingsRow(icon: "clock.fill", title: "Daily Goal", value: "15 min", color: .green)
    }
}
