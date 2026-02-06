import SwiftUI

struct TheaterView: View {
    let scenarioId: String
    let namespace: Namespace.ID
    
    @EnvironmentObject var observer: SDKObserver
    @Environment(\.dismiss) var dismiss
    
    @State private var textInput = ""
    @State private var isRecording = false
    @State private var dialogLines: [MockDialogLine] = []
    
    struct MockDialogLine: Identifiable {
        let id = UUID()
        let text: String
        let role: String
        let isUser: Bool
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.secondary)
                        .padding(8)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
                
                Spacer()
                
                Text("Scenario Active")
                    .font(.headline)
                
                Spacer()
                
                Color.clear.frame(width: 32, height: 32)
            }
            .padding()
            .background(.bar)
            
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 20) {
                        Color.clear.frame(height: 20)
                        
                        ForEach(dialogLines) { line in
                            DialogBubble(
                                text: line.text,
                                roleName: line.role,
                                isUser: line.isUser
                            )
                            .id(line.id)
                        }
                    }
                    .padding()
                }
                .onChange(of: dialogLines.count) {
                    if let last = dialogLines.last {
                        withAnimation {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            VStack(spacing: 16) {
                DirectorToolbar(
                    onHint: {
                        addLine("Try asking about the dark roast.", role: "System", isUser: false)
                    },
                    onReplay: {
                        
                    },
                    onEnd: {
                        dismiss()
                    }
                )
                
                HStack(spacing: 12) {
                    TextField("Type your response...", text: $textInput)
                        .padding()
                        .background(Color(.systemGray6))
                        .clipShape(Capsule())
                        .submitLabel(.send)
                        .onSubmit {
                            sendUserMessage()
                        }
                    
                    Button {
                        isRecording.toggle()
                    } label: {
                        Image(systemName: isRecording ? "waveform" : "mic.fill")
                            .font(.title2)
                            .foregroundStyle(.white)
                            .frame(width: 50, height: 50)
                            .background(isRecording ? Color.red.gradient : Color.blue.gradient)
                            .clipShape(Circle())
                            .symbolEffect(.breathe, isActive: isRecording)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .background(.bar)
        }
        .navigationBarHidden(true)
        .navigationTransition(.zoom(sourceID: scenarioId, in: namespace))
        .onAppear {
            if dialogLines.isEmpty {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    addLine("Good morning! What can I get started for you?", role: "Barista", isUser: false)
                }
            }
        }
    }
    
    private func sendUserMessage() {
        guard !textInput.isEmpty else { return }
        let text = textInput
        textInput = ""
        addLine(text, role: "You", isUser: true)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            addLine("Sure thing! That'll be $4.50.", role: "Barista", isUser: false)
        }
    }
    
    private func addLine(_ text: String, role: String, isUser: Bool) {
        let newLine = MockDialogLine(text: text, role: role, isUser: isUser)
        dialogLines.append(newLine)
    }
}
