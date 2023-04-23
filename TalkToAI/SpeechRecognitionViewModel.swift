import SwiftUI
import Combine
import Speech
import AVFoundation

class SpeechRecognitionViewModel: ObservableObject {
    @Published var recognizedText: String = ""
    @Published var buttonText: String = "Listen"
    @Published var isScenarioStarting: Bool = false
    @Published var showSettings: Bool = false
    
    private let audioEngine = AVAudioEngine()
    private let chatGPTService: GptServiceProtocol
    private let requestedPermissionKey = "SpeechRecognitionRequestedPermission"
    private let speechSynthesizerManager: SpeechSynthesizerManager
    private let recognitionPlaceholderText: String = "Listening..."
    
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var chatProcessor: ChatProcessor
    private var chatGPTTask: URLSessionDataTask?
    
    
    init(chatGPTService: GptServiceProtocol,
         speechSynthesizerManager: SpeechSynthesizerManager,
         chatProcessor: ChatProcessor) {
        self.chatGPTService = chatGPTService
        self.speechSynthesizerManager = speechSynthesizerManager
        self.chatProcessor = chatProcessor
    }
    
    func startConversationFromScenario( scenarioId: String, language: Language) {
        
        let scenario = Scenario.scenarios[scenarioId] ?? ""
        
        if (scenarioId == "" || scenario == ""){
            chatProcessor.initWithHumanMessage (content: "Hi"){
                self.sendMessagesToChatGPT(language: language)
            }
            return
        }
        
        DispatchQueue.main.async {
            self.isScenarioStarting = true
        }
        
        self.chatProcessor.initWithScenario(content: scenario){
            self.sendMessagesToChatGPT(language: language){
                DispatchQueue.main.async {
                    self.isScenarioStarting = false
                }
            }
        }
    }
    
    func toggleSpeechRecognition(language: Language) {
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            
            DispatchQueue.main.async {
                self.buttonText = "Listen"
            }

            if(recognizedText != recognitionPlaceholderText){
                chatProcessor.addHumanMessage(content: recognizedText){
                    self.sendMessagesToChatGPT(language: language)
                }
            }

            // Reset recognition state
            let inputNode = audioEngine.inputNode
            inputNode.removeTap(onBus: 0)
            recognitionRequest = nil
            recognitionTask = nil
            DispatchQueue.main.async {
                self.recognizedText = ""
            }
        } else {
            let authorizationStatus = SFSpeechRecognizer.authorizationStatus()
            
            if authorizationStatus == .authorized {
                try? startSpeechRecognition(language: language)
                
                DispatchQueue.main.async {
                    self.buttonText = "Stop"
                }
            } else if authorizationStatus == .notDetermined {
                if UserDefaults.standard.bool(forKey: requestedPermissionKey) {
                    SFSpeechRecognizer.requestAuthorization { status in
                        DispatchQueue.main.async {
                            if status == .authorized {
                                try? self.startSpeechRecognition(language: language)
                                self.buttonText = "Stop"
                            } else {
                                self.recognizedText = "Speech recognition not authorized."
                            }
                        }
                    }
                } else {
                    UserDefaults.standard.set(true, forKey: requestedPermissionKey)
                    SFSpeechRecognizer.requestAuthorization { status in
                        DispatchQueue.main.async {
                            if status == .authorized {
                                try? self.startSpeechRecognition(language: language)
                                self.buttonText = "Stop"
                            } else {
                                self.recognizedText = "Speech recognition not authorized."
                            }
                        }
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.recognizedText = "Speech recognition not authorized."
                }
            }
        }
    }

    private func startSpeechRecognition(language: Language) throws {
        if let recognitionTask = recognitionTask {
            recognitionTask.cancel()
            self.recognitionTask = nil
        }
        
        speechSynthesizerManager.stopSpeaking()

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()

        let inputNode = audioEngine.inputNode

        guard let recognitionRequest = recognitionRequest else { fatalError("Unable to create a SFSpeechAudioBufferRecognitionRequest object") }

        recognitionRequest.shouldReportPartialResults = true
        
        let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: getLanguageCode(language: language)))!
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            if let result = result {
                DispatchQueue.main.async {
                    let recognizedText = result.bestTranscription.formattedString
                    self.recognizedText = recognizedText
                }
            }
            if error != nil {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                DispatchQueue.main.async {
                    self.buttonText = "Listen"
                }
            }
        }

        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
            self.recognitionRequest?.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()
        
        DispatchQueue.main.async {
            self.recognizedText = self.recognitionPlaceholderText
        }
    }
    
    func getLanguageCode(language: Language) -> String {
        switch language {
        case .english:
            return "en_US"
        case .russian:
            return "ru_RU"
        }
    }
    
    
    
    func sendMessagesToChatGPT(language: Language, completion: @escaping () -> Void = {}) {
        chatProcessor.setGptThinking(){
            if let chatGPTTask = self.chatGPTTask {
                chatGPTTask.cancel()
                self.chatGPTTask = nil
            }
            self.chatGPTTask = self.chatGPTService.sendMessage(messages: self.chatProcessor.messages) { [weak self] result
                in guard let self = self else { return }
                
                chatProcessor.unsetGptThinking()
                
                switch result {
                case .success(let response):
                    chatProcessor.addGptMessage(content: response)
                    speechSynthesizerManager.speakText(text: response, language: language)
                case .failure(let error):
                    print(error)
                    chatProcessor.showError("Failed to get a response from ChatGPT: \(error.localizedDescription)")
                }
                completion()
            }
        }
    }
    
    func cancelChatGPTRequest() {
        chatGPTTask?.cancel()
        chatProcessor.unsetGptThinking()
    }
    
    func repeatLastChatGPTMessage(language: Language) {
        if speechSynthesizerManager.isSpeaking {
            speechSynthesizerManager.speechSynthesizer.stopSpeaking(at: .immediate)
            speechSynthesizerManager.isSpeaking = false
        } else {
            if let lastGptMessage = chatProcessor.getLastGptActualMessage()?.content {
                speechSynthesizerManager.isSpeaking = true
                speechSynthesizerManager.speakText(text: lastGptMessage, language: language)
            }
        }
    }
}
