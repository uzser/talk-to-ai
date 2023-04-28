import Foundation

struct Message: Identifiable, Hashable {
    let id = UUID()
    let sender: String
    var content: String
    let isLoadingMessage: Bool
    var isHiddenToGPT: Bool
    
    init(sender: String, content: String, isLoadingMessage: Bool = false) {
        self.sender = sender
        self.content = content
        self.isLoadingMessage = isLoadingMessage
        self.isHiddenToGPT = false
    }
}
