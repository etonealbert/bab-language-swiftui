import SwiftUI

struct VoiceInputBar: View {
    @ObservedObject var speechManager: SpeechManager
    @AppStorage("micEnabled") private var micEnabled = true
    let onConfirmTap: () -> Void
    let onSkip: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            Button {
                if micEnabled {
                    speechManager.toggleListening()
                } else {
                    onConfirmTap()
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(speechManager.isListening ? Color.red : Color.accentColor)
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: micEnabled ? "mic.fill" : "hand.tap.fill")
                        .font(.title2)
                        .foregroundStyle(.white)
                }
            }
            
            if micEnabled && speechManager.isListening {
                AudioWaveformView(level: speechManager.audioLevel)
                    .frame(height: 30)
            } else {
                Text(micEnabled ? "Tap to speak" : "Tap to confirm")
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Button("Skip", action: onSkip)
                .buttonStyle(.bordered)
        }
        .padding()
        .background(.ultraThinMaterial)
    }
}
