import SwiftUI

struct ContentView: View {
    private enum Field: Int, CaseIterable {
        case input
    }
    
    @EnvironmentObject var viewModel: SpeechRecognitionViewModel
    @StateObject var speechSynthesizerManager: SpeechSynthesizerManager
    @StateObject var chatProcessor: ChatProcessor
    @State private var selectedItem: String = ""
    @State private var previousSelectedItem: String = ""
    @State private var scrollToId: UUID? = nil
    @State private var language: Language = Language.english
    @FocusState private var focusedField: Field?

    var body: some View {
        VStack {
            ScrollViewReader { proxy in
                ZStack {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 10) {
                            ForEach(chatProcessor.messages, id: \.self.id) { message in
                                VStack(alignment: .leading) {
                                    Text(message.sender)
                                        .font(.headline)
                                    Text(message.content)
                                        .italic(message.isLoadingMessage)
                                }
                                .id(message.id)
                                .textSelection(.enabled)
                                .frame(minWidth: 60, alignment: .leading)
                                .padding(5)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(8)
                                .padding(.horizontal)
                            }
                            .cornerRadius(8)
                        }
                    }
                }
                .onChange(of: chatProcessor.messages) { _ in
                    if let lastMessageID = chatProcessor.messages.last?.id {
                        proxy.scrollTo(lastMessageID, anchor: .bottom)
                    }
                }
            }
            .frame(maxHeight: .infinity)
            

            TextField("Recognized text", text: $viewModel.recognizedText, axis: .vertical)
                .multilineTextAlignment(.leading)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .lineLimit(5)
                .focused($focusedField, equals: .input)
                .frame(maxWidth: .infinity)
            
            if(chatProcessor.isChatGptThinking && !viewModel.isScenarioStarting){
                Button(action: {
                    viewModel.cancelChatGPTRequest()
                }) {
                    Text("Stop thinking")
                }
                .padding(5)
            }
            else{
                Button(action: {
                    viewModel.toggleSpeechRecognition(language: language)
                    focusedField = nil
                }) {
                    Text(viewModel.buttonText)
                }
                .disabled(viewModel.isScenarioStarting)
                .padding(5)
            }
            
            Button(action: {
                viewModel.repeatLastChatGPTMessage(language: language)
            }) {
                Text(speechSynthesizerManager.isSpeaking ? "Stop speaking" : "Repeat")
            }
            .padding(5)
            
            HStack {
                Picker("Select a scenario", selection: $selectedItem) {
                    Text("").tag("")
                    ForEach(Scenario.scenarios.keys.sorted(), id: \.self) { key in
                        Text(key).tag(key)
                    }
                    .pickerStyle(MenuPickerStyle())
                    .onChange(of: selectedItem) { newValue in
                        if newValue != previousSelectedItem {
                            viewModel.startConversationFromScenario(scenarioId: newValue, language: language)
                            previousSelectedItem = newValue
                            focusedField = nil
                        }
                    }
                }
                
                Picker("", selection: $language) {
                    ForEach(Language.allCases, id: \.self) { lang in
                        Text(lang.rawValue).tag(lang)
                    }
                    .pickerStyle(MenuPickerStyle())
                    .onChange(of: selectedItem) { newValue in
                        if newValue != previousSelectedItem {
                            viewModel.startConversationFromScenario(scenarioId: newValue, language: language)
                            previousSelectedItem = newValue
                            focusedField = nil
                        }
                    }
                }
                .frame(maxWidth: 70)
                
                
                Button(action: {
                    viewModel.startConversationFromScenario(scenarioId: selectedItem, language: language)
                    focusedField = nil
                }) {
                    Text("Restart")
                }
                .padding(5)
                
#if !os(iOS) && !os(macOS)
                // TODO: Settings
                Button(action: {
                    viewModel.showSettings = true
                }) {
                    Text("Settings")
                }
                .sheet(isPresented: viewModel.showSettings) {
                    SettingsView()
                }
#endif
            }
        }
        .padding()
        
        if !chatProcessor.errorText.isEmpty {
            VStack {
                HStack {
                    Spacer()
                    Text(chatProcessor.errorText)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(8)
                    Spacer()
                }
            }
        }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(speechSynthesizerManager: SpeechSynthesizerManager(),
                    chatProcessor: configuredChatProcessor)
            .environmentObject(SpeechRecognitionViewModel(chatGPTService: GptServiceStub(),
                                                          speechSynthesizerManager: SpeechSynthesizerManager(),
                                                          chatProcessor: configuredChatProcessor))
    }

    static var configuredChatProcessor: ChatProcessor {
        let chatProcessor = ChatProcessor()
        chatProcessor.messages = [
            Message(sender: SenderName.human, content: "Hello", isLoadingMessage: false),
            Message(sender: SenderName.gpt, content: "Hello. How can I help you?", isLoadingMessage: false),
            Message(sender: SenderName.human, content: "What can you do? You're just a machine. Only imitation of life. Can AI compose a symphony? Turn a piece of canvas into a masterpiece of art?", isLoadingMessage: false),
            Message(sender: SenderName.gpt, content: "And you?", isLoadingMessage: false)
        ]
        
        return chatProcessor
    }
}
