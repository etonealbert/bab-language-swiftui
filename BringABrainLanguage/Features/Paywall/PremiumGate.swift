import SwiftUI

struct PremiumGate<Content: View>: View {
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    
    let content: () -> Content
    
    @State private var showPaywall = false
    
    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }
    
    var body: some View {
        Group {
            if subscriptionManager.subscriptionStatus == .subscribed {
                content()
            } else {
                content()
                    .overlay {
                        ZStack {
                            Color.black.opacity(0.4)
                            
                            VStack(spacing: 8) {
                                Image(systemName: "lock.fill")
                                    .font(.title)
                                    .symbolEffect(.bounce, options: .default)
                                Text("Premium")
                                    .font(.caption.bold())
                            }
                            .foregroundStyle(.white)
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .onTapGesture { showPaywall = true }
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView { showPaywall = false }
        }
    }
}

#Preview {
    PremiumGate {
        Text("Premium Content")
            .frame(width: 200, height: 100)
            .background(.purple.gradient)
    }
}
