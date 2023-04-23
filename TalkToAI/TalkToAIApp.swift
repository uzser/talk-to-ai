import SwiftUI
import Speech

@main
struct TalkToAIApp: App {
    
    // TODO: Move to settings
    let apiKey = "OPENAI_API_KEY"
    
    var viewModel: SpeechRecognitionViewModel
    let speechSynthesizerManager: SpeechSynthesizerManager
    let chatProcessor: ChatProcessor

    init() {
        let chatGPTService = GptService(apiKey: apiKey)
        
        // Uncomment to use a stub service instead of the real one
        //let chatGPTService = ChatGPTStubService()

        speechSynthesizerManager = SpeechSynthesizerManager()
        chatProcessor = ChatProcessor()
        viewModel = SpeechRecognitionViewModel(chatGPTService: chatGPTService,
                                               speechSynthesizerManager: speechSynthesizerManager,
                                               chatProcessor: chatProcessor)
    }

    var body: some Scene {
        WindowGroup {
            ContentView(speechSynthesizerManager: speechSynthesizerManager, chatProcessor: chatProcessor)
                .environmentObject(viewModel)
        }
#if os(macOS)
        // TODO: Settings
        .commands {
            MainMenu(viewModel: viewModel)
        }
#endif
        
    }
}
