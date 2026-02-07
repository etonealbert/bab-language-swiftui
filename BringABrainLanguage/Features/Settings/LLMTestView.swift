import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct LLMTestMessage: Identifiable, Equatable {
    let id: UUID
    let content: String
    let isUser: Bool
    let timestamp: Date
    
    init(id: UUID = UUID(), content: String, isUser: Bool, timestamp: Date = Date()) {
        self.id = id
        self.content = content
        self.isUser = isUser
        self.timestamp = timestamp
    }
}

struct LLMTestView: View {
    @State private var messages: [LLMTestMessage] = []
    @State private var inputText: String = ""
    @State private var isGenerating: Bool = false
    @State private var llmAvailability: LLMAvailability = .unknown
    
    private let llmBridge = LLMBridge()
    
    private var grayBackground: Color {
        #if canImport(UIKit)
        Color(UIColor.systemGray5)
        #else
        Color.gray.opacity(0.2)
        #endif
    }
    
    private var inputBackground: Color {
        #if canImport(UIKit)
        Color(UIColor.systemGray6)
        #else
        Color.gray.opacity(0.1)
        #endif
    }
    
    var body: some View {
        VStack(spacing: 0) {
            availabilityBanner
            
            messageList
            
            inputBar
        }
        .navigationTitle("LLM Test")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .onAppear {
            checkAvailability()
            initializeSession()
        }
    }
    
    @ViewBuilder
    private var availabilityBanner: some View {
        switch llmAvailability {
        case .available:
            EmptyView()
        case .notSupported:
            statusBanner(
                icon: "exclamationmark.triangle.fill",
                message: "Device not supported. Requires iPhone 15 Pro+ or M-series iPad.",
                color: .red
            )
        case .modelNotReady:
            statusBanner(
                icon: "arrow.down.circle.fill",
                message: "Model is downloading. Please wait...",
                color: .orange
            )
        case .unknown:
            statusBanner(
                icon: "questionmark.circle.fill",
                message: "Checking availability...",
                color: .gray
            )
        }
    }
    
    private func statusBanner(icon: String, message: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding()
        .background(color.opacity(0.1))
    }
    
    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    if messages.isEmpty && isAvailable {
                        emptyState
                    }
                    
                    ForEach(messages) { message in
                        messageBubble(message)
                            .id(message.id)
                    }
                    
                    if isGenerating {
                        typingIndicator
                            .id("typing")
                    }
                }
                .padding()
            }
            .onChange(of: messages.count) {
                if let last = messages.last {
                    withAnimation {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
            .onChange(of: isGenerating) { _, generating in
                if generating {
                    withAnimation {
                        proxy.scrollTo("typing", anchor: .bottom)
                    }
                }
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.system(size: 48))
                .foregroundColor(.secondary.opacity(0.5))
            
            Text("Start a conversation")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Type a message below to test the on-device LLM")
                .font(.subheadline)
                .foregroundColor(.secondary.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding(.top, 60)
    }
    
    private func messageBubble(_ message: LLMTestMessage) -> some View {
        HStack {
            if message.isUser { Spacer(minLength: 60) }
            
            Text(message.content)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(message.isUser ? Color.blue : grayBackground)
                .foregroundColor(message.isUser ? .white : .primary)
                .clipShape(RoundedRectangle(cornerRadius: 18))
            
            if !message.isUser { Spacer(minLength: 60) }
        }
    }
    
    private var typingIndicator: some View {
        HStack {
            HStack(spacing: 4) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color.secondary)
                        .frame(width: 8, height: 8)
                        .opacity(isGenerating ? 1 : 0.3)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(grayBackground)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            
            Spacer()
        }
    }
    
    private var inputBar: some View {
        HStack(spacing: 12) {
            TextField("Type a message...", text: $inputText, axis: .vertical)
                .textFieldStyle(.plain)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(inputBackground)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .lineLimit(1...5)
                .disabled(!isAvailable || isGenerating)
            
            Button {
                sendMessage()
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(canSend ? .blue : .gray)
            }
            .disabled(!canSend)
        }
        .padding()
        .background(.bar)
    }
    
    private var isAvailable: Bool {
        llmAvailability == .available
    }
    
    private var canSend: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && isAvailable
            && !isGenerating
    }
    
    private func checkAvailability() {
        llmAvailability = llmBridge.checkAvailability()
    }
    
    private func initializeSession() {
        guard isAvailable else { return }
        
        Task {
            let systemPrompt = """
            You are a helpful AI assistant for testing purposes. 
            Keep responses concise and helpful.
            """
            _ = await llmBridge.initialize(systemPrompt: systemPrompt)
        }
    }
    
    private func sendMessage() {
        let trimmedInput = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedInput.isEmpty else { return }
        
        let userMessage = LLMTestMessage(content: trimmedInput, isUser: true)
        messages.append(userMessage)
        inputText = ""
        
        isGenerating = true
        
        Task {
            do {
                let response = try await llmBridge.generate(prompt: trimmedInput)
                let assistantMessage = LLMTestMessage(content: response, isUser: false)
                await MainActor.run {
                    messages.append(assistantMessage)
                    isGenerating = false
                }
            } catch {
                let errorMessage = LLMTestMessage(
                    content: "Error: \(error.localizedDescription)",
                    isUser: false
                )
                await MainActor.run {
                    messages.append(errorMessage)
                    isGenerating = false
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        LLMTestView()
    }
}
