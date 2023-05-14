import AVFoundation

class SpeechSynthesizerManager: NSObject, AVSpeechSynthesizerDelegate, ObservableObject {
    @Published var isSpeaking: Bool = false
    let speechSynthesizer = AVSpeechSynthesizer()
    
    override init() {
        super.init()
        speechSynthesizer.delegate = self
    }
    
    func speakText(text: String, language: Language) {
        let utterance = AVSpeechUtterance(string: text)
        
        utterance.voice = getVoice(language: language)
        
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        speechSynthesizer.speak(utterance)
    }
    
    func getVoice(language: Language) -> AVSpeechSynthesisVoice? {

        let langCode: String
        switch language {
        case .english:
            langCode = "en-US"
            if let bestVoice = AVSpeechSynthesisVoice.speechVoices().first(where: { $0.identifier.contains("com.apple.ttsbundle.siri_Aaron_en-US_compact")}){
                return bestVoice
            }
        case .russian:
            langCode = "ru-RU"
        case .hebrew:
            langCode = "he-IL"
        }
        return AVSpeechSynthesisVoice(language: langCode)
    }
    
    func stopSpeaking() {
        speechSynthesizer.stopSpeaking(at: .immediate)
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = true
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = false
        }
    }
}
