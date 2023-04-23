struct GPT3ErrorResponse: Codable {
    let error: GPT3Error

    struct GPT3Error: Codable {
        let message: String
        let type: String
        let param: String?
        let code: String
    }
}
