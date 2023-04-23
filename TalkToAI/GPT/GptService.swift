import Foundation

protocol GptServiceProtocol {
    func sendMessage(messages: [Message], completion: @escaping (Result<String, Error>) -> Void) -> URLSessionDataTask
}

class GptServiceStub: GptServiceProtocol {
    func sendMessage(messages: [Message], completion: @escaping (Result<String, Error>) -> Void) -> URLSessionDataTask {
        print("ChatGPTStubService.sendMessage")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            completion(.success("This is a stubbed response from ChatGPT. This is a stubbed response from ChatGPT. This is a stubbed response from ChatGPT. This is a stubbed response from ChatGPT. This is a stubbed response from ChatGPT. This is a stubbed response from ChatGPT. This is a stubbed response from ChatGPT. This is a stubbed response from ChatGPT. This is a stubbed response from ChatGPT. This is a stubbed response from ChatGPT. This is a stubbed response from ChatGPT. This is a stubbed response from ChatGPT. This is a stubbed response from ChatGPT. This is a stubbed response from ChatGPT."))
            
            // Uncomment to test error handling
            //completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "This is a stubbed error."])))
        }
        
        return GptService.emptyTask()
    }
}

class GptService: GptServiceProtocol {
    private let apiKey: String
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    func sendMessage(messages: [Message], completion: @escaping (Result<String, Error>) -> Void) -> URLSessionDataTask {
        
        let messagesFormatted = messages.filter({ $0.isLoadingMessage == false })
            .map { ["role":
                        $0.sender == SenderName.human ? "user" :
                        ($0.sender == SenderName.introduction ? "system" :
                            "assistant"),
                    "content": $0.content] }
        
        
        print(messagesFormatted)

        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return GptService.emptyTask()
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let requestBody: [String: Any] = [
            "model": "gpt-3.5-turbo",
            "messages": messagesFormatted
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])
        } catch {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to encode request body"])))
            return GptService.emptyTask()
        }

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            print(response as Any)
            
            if let error = error {
                // Check if the error is due to the task being canceled
                if (error as NSError).code == NSURLErrorCancelled && (error as NSError).domain == NSURLErrorDomain {
                    // If the task was canceled, do nothing
                    return
                } else {
                    // If the error is not due to cancellation, pass it to the completion handler
                    completion(.failure(error))
                    return
                }
            }

            guard let data = data else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }

            do {
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                    let errorResponse = try JSONDecoder().decode(GPT3ErrorResponse.self, from: data)
                    let error = NSError(domain: "", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorResponse.error.message])
                    completion(.failure(error))
                } else {
                    let decodedResponse = try JSONDecoder().decode(GPT3Response.self, from: data)
                    if let message = decodedResponse.choices.first?.message.content.trimmingCharacters(in: .whitespacesAndNewlines) {
                        completion(.success(message))
                    } else {
                        completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse response"])))
                    }
                }
            } catch {
                completion(.failure(error))
            }
        }

        task.resume()
        return task
    }
    
    static func emptyTask() -> URLSessionDataTask {
        let dummyRequest = URLRequest(url: URL(string: "https://example.com")!)
        return URLSession.shared.dataTask(with: dummyRequest) { _, _, _ in }
    }
}
