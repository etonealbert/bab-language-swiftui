import SwiftUI

struct ScenarioCard: View {
    let scenario: ScenarioDisplayData
    let namespace: Namespace.ID
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topTrailing) {
                Color.purple.opacity(0.1)
                
                Image(systemName: scenario.imageName)
                    .font(.system(size: 60))
                    .foregroundStyle(.purple.gradient)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                
                if scenario.isPremium {
                    Image(systemName: "lock.fill")
                        .foregroundStyle(.white)
                        .padding(8)
                        .background(Circle().fill(.black.opacity(0.6)))
                        .padding(8)
                }
            }
            .frame(height: 120)
            .clipped()
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(scenario.name)
                        .font(.headline)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Text(scenario.difficulty)
                        .font(.caption2.bold())
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                }
                
                Text(scenario.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            .padding(12)
            .background(.background)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(.quaternary, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        .matchedTransitionSource(id: scenario.id, in: namespace)
    }
}
