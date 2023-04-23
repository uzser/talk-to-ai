struct GPT3Response: Codable {
    let id: String
    let object: String
    let created: Int
    let choices: [Choice]
    let usage: Usage

    struct Choice: Codable {
        let index: Int
        let message: Message
        let finish_reason: String

        struct Message: Codable {
            let role: String
            let content: String
        }
    }

    struct Usage: Codable {
        let prompt_tokens: Int
        let completion_tokens: Int
        let total_tokens: Int
    }
}
