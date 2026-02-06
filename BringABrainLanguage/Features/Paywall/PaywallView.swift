import SwiftUI
import StoreKit

struct PaywallView: View {
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @Environment(\.dismiss) private var dismiss
    
    let onContinueFree: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 12) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 60))
                    .foregroundStyle(.purple.gradient)
                    .symbolEffect(.breathe)
                
                Text("Unlock Your Full Potential")
                    .font(.title.bold())
                
                Text("Get unlimited scenarios, cloud sync, and online multiplayer")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 40)
            
            Spacer()
            
            FeatureListView()
            
            Spacer()
            
            if subscriptionManager.isLoading {
                ProgressView()
            } else {
                VStack(spacing: 12) {
                    ForEach(subscriptionManager.availableProducts, id: \.id) { product in
                        ProductButton(product: product) {
                            await purchase(product)
                        }
                    }
                }
            }
            
            Button("Continue with Free Version") {
                onContinueFree()
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .padding(.top, 8)
            
            Button("Restore Purchases") {
                Task { await subscriptionManager.restorePurchases() }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            
            LegalLinksView()
                .padding(.bottom)
        }
        .padding(.horizontal, 24)
    }
    
    private func purchase(_ product: Product) async {
        do {
            let success = try await subscriptionManager.purchase(product)
            if success {
                dismiss()
            }
        } catch {
            print("Purchase failed: \(error)")
        }
    }
}

struct FeatureListView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            FeatureRow(icon: "theatermasks.fill", text: "20+ immersive scenarios")
            FeatureRow(icon: "globe", text: "Online multiplayer worldwide")
            FeatureRow(icon: "icloud.fill", text: "Sync progress across devices")
            FeatureRow(icon: "chart.line.uptrend.xyaxis", text: "Advanced vocabulary analytics")
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.purple)
                .frame(width: 32)
            
            Text(text)
                .font(.subheadline)
        }
    }
}

struct ProductButton: View {
    let product: Product
    let onPurchase: () async -> Void
    
    @State private var isPurchasing = false
    
    var body: some View {
        Button {
            isPurchasing = true
            Task {
                await onPurchase()
                isPurchasing = false
            }
        } label: {
            HStack {
                VStack(alignment: .leading) {
                    Text(product.displayName)
                        .font(.headline)
                    Text(product.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                if isPurchasing {
                    ProgressView()
                } else {
                    Text(product.displayPrice)
                        .font(.headline)
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .disabled(isPurchasing)
    }
}

struct LegalLinksView: View {
    var body: some View {
        HStack(spacing: 16) {
            Link("Privacy Policy", destination: URL(string: "https://bablabs.com/privacy")!)
            Text("•")
            Link("Terms of Use", destination: URL(string: "https://bablabs.com/terms")!)
        }
        .font(.caption2)
        .foregroundStyle(.secondary)
    }
}

#Preview {
    PaywallView { }
}
