import SwiftUI
import Combine

class ChatProcessor: ObservableObject {
    
    @Published var isChatGptThinking: Bool = false
    @Published var errorText: String = ""
    @Published var messages: [Message] = []
    
    
    private var errorDisplayTimer: AnyCancellable?
    private var thinkingTimer: Timer?
    
    func addHumanMessage(content: String, completion: @escaping () -> Void = {}) {
        self.addMessage(sender: SenderName.human, content: content, completion: completion)
    }
    
    func addGptMessage(content: String, completion: @escaping () -> Void = {}) {
        self.addMessage(sender: SenderName.gpt, content: content, completion: completion)
    }
    
    func initWithScenario(content: String, completion: @escaping () -> Void = {}) {
        cleanMessages()
        self.addMessage(sender: SenderName.introduction, content: content)
        self.addMessage(sender: SenderName.human, content: "Hi", completion: completion)
    }
    
    func initWithHumanMessage(content: String, completion: @escaping () -> Void = {}) {
        cleanMessages()
        addHumanMessage(content: content, completion: completion)
    }
    
    private func addMessage(sender: String, content: String, isLoadingMessage: Bool = false, completion: @escaping () -> Void = {}) {
        DispatchQueue.main.async {
            let newMessage = Message(sender: sender, content: content, isLoadingMessage: isLoadingMessage)
            self.messages.append(newMessage)
            completion()
        }
    }
    
    func cleanMessages() {
        DispatchQueue.main.async {
            self.messages.removeAll()
        }
    }
    
    func setGptThinking(completion: @escaping () -> Void = {}) {
        DispatchQueue.main.async {
            self.isChatGptThinking = true
            self.addMessage(sender: SenderName.gpt, content: "thinking", isLoadingMessage: true, completion: completion)
            self.startThinkingAnimation()
        }
    }
    
    private func startThinkingAnimation() {
        var counter = 0
        thinkingTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] timer in
            DispatchQueue.main.async {
                guard let self = self, self.isChatGptThinking, let lastIndex = self.messages.indices.last, self.messages[lastIndex].sender == SenderName.gpt else {
                    timer.invalidate()
                    return
                }
                let baseMessage = "thinking"
                let dots = String(repeating: ".", count: counter % 4)
                self.messages[lastIndex].content = baseMessage + dots
                counter += 1
            }
        }
    }

    
    func unsetGptThinking() {
        DispatchQueue.main.async {
            self.isChatGptThinking = false
            self.messages.removeAll(where: { $0.isLoadingMessage })
        }
        self.thinkingTimer?.invalidate()
    }
    
    func showError(_ message: String) {
        DispatchQueue.main.async {
            self.errorText = message
            self.errorDisplayTimer = Just(()).delay(for: .seconds(6), scheduler: RunLoop.main).sink { [weak self] _ in
                self?.errorText = ""
            }
        }
    }
    
    func getLastGptActualMessage() -> Message? {
        return messages.reversed().first { $0.sender == SenderName.gpt && $0.isLoadingMessage == false }
    }
}

