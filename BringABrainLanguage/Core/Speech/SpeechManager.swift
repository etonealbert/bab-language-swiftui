import SwiftUI
import Speech
#if os(iOS)
import AVFoundation
#endif

@MainActor
class SpeechManager: ObservableObject {
    @Published var isListening = false
    @Published var audioLevel: Float = 0
    @Published var recognizedText: String = ""
    @Published var matchedWordCount: Int = 0
    @Published var authorizationStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined
    @Published var errorMessage: String?
    
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    private var expectedWords: [String] = []
    private var targetLanguage: String = "en-US"
    
    var onAllWordsMatched: (() -> Void)?
    var onWordMatched: ((Int) -> Void)?
    
    init() {
        checkAuthorizationStatus()
    }
    
    func checkAuthorizationStatus() {
        authorizationStatus = SFSpeechRecognizer.authorizationStatus()
    }
    
    func requestAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                Task { @MainActor in
                    self.authorizationStatus = status
                    continuation.resume(returning: status == .authorized)
                }
            }
        }
    }
    
    func startListening(expectedLine: String, language: String) {
        guard authorizationStatus == .authorized else {
            errorMessage = "Speech recognition not authorized"
            return
        }
        
        stopListening()
        matchedWordCount = 0
        recognizedText = ""
        errorMessage = nil
        
        expectedWords = normalizeToWords(expectedLine)
        targetLanguage = language
        
        guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: language)),
              recognizer.isAvailable else {
            errorMessage = "Speech recognition not available for \(language)"
            return
        }
        
        speechRecognizer = recognizer
        
        do {
            try startAudioEngine()
            isListening = true
        } catch {
            errorMessage = "Failed to start audio: \(error.localizedDescription)"
        }
    }
    
    func stopListening() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
        isListening = false
        audioLevel = 0
    }
    
    func toggleListening() {
        if isListening {
            stopListening()
        } else if !expectedWords.isEmpty {
            startListening(
                expectedLine: expectedWords.joined(separator: " "),
                language: targetLanguage
            )
        }
    }
    
    private func startAudioEngine() throws {
        #if os(iOS)
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        #endif
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            throw SpeechError.recognitionRequestFailed
        }
        
        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.requiresOnDeviceRecognition = false
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                
                if let result = result {
                    self.processRecognitionResult(result)
                }
                
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    self.stopListening()
                }
            }
        }
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
            
            let channelData = buffer.floatChannelData?[0]
            let frameLength = Int(buffer.frameLength)
            
            if let channelData = channelData {
                var sum: Float = 0
                for i in 0..<frameLength {
                    sum += abs(channelData[i])
                }
                let average = sum / Float(frameLength)
                
                Task { @MainActor [weak self] in
                    self?.audioLevel = min(average * 10, 1.0)
                }
            }
        }
        
        audioEngine.prepare()
        try audioEngine.start()
    }
    
    private func processRecognitionResult(_ result: SFSpeechRecognitionResult) {
        let spokenText = result.bestTranscription.formattedString
        recognizedText = spokenText
        
        let spokenWords = normalizeToWords(spokenText)
        
        var newMatchCount = 0
        for (index, expectedWord) in expectedWords.enumerated() {
            guard index < spokenWords.count else { break }
            
            if lenientMatch(spoken: spokenWords[index], expected: expectedWord) {
                newMatchCount = index + 1
            } else {
                break
            }
        }
        
        if newMatchCount > matchedWordCount {
            matchedWordCount = newMatchCount
            onWordMatched?(matchedWordCount)
            
            if matchedWordCount == expectedWords.count {
                stopListening()
                onAllWordsMatched?()
            }
        }
    }
    
    private func normalizeToWords(_ text: String) -> [String] {
        text.components(separatedBy: .whitespacesAndNewlines)
            .map { word in
                word.lowercased()
                    .folding(options: .diacriticInsensitive, locale: nil)
                    .filter { $0.isLetter || $0.isNumber }
            }
            .filter { !$0.isEmpty }
    }
    
    private func lenientMatch(spoken: String, expected: String) -> Bool {
        if spoken == expected {
            return true
        }
        return levenshteinSimilarity(spoken, expected) >= 0.8
    }
    
    private func levenshteinSimilarity(_ s1: String, _ s2: String) -> Double {
        let distance = levenshteinDistance(s1, s2)
        let maxLength = max(s1.count, s2.count)
        guard maxLength > 0 else { return 1.0 }
        return 1.0 - (Double(distance) / Double(maxLength))
    }
    
    private func levenshteinDistance(_ s1: String, _ s2: String) -> Int {
        let a = Array(s1)
        let b = Array(s2)
        
        var dist = [[Int]](repeating: [Int](repeating: 0, count: b.count + 1), count: a.count + 1)
        
        for i in 0...a.count {
            dist[i][0] = i
        }
        for j in 0...b.count {
            dist[0][j] = j
        }
        
        for i in 1...a.count {
            for j in 1...b.count {
                if a[i-1] == b[j-1] {
                    dist[i][j] = dist[i-1][j-1]
                } else {
                    dist[i][j] = min(
                        dist[i-1][j] + 1,   // deletion
                        dist[i][j-1] + 1,   // insertion
                        dist[i-1][j-1] + 1  // substitution
                    )
                }
            }
        }
        
        return dist[a.count][b.count]
    }
}

enum SpeechError: LocalizedError {
    case recognitionRequestFailed
    case audioSessionFailed
    case recognizerNotAvailable
    
    var errorDescription: String? {
        switch self {
        case .recognitionRequestFailed:
            return "Failed to create speech recognition request"
        case .audioSessionFailed:
            return "Failed to configure audio session"
        case .recognizerNotAvailable:
            return "Speech recognizer not available for this language"
        }
    }
}
