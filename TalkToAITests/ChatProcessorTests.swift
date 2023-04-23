import XCTest
@testable import TalkToAI

final class ChatProcessorTests: XCTestCase {

    func testAddHumanMessage() {
        let chatProcessor = ChatProcessor()
        let content = "Hello, ChatGPT!"
        
        let expectation = self.expectation(description: "Wait for the async block to complete")
        
        chatProcessor.addHumanMessage(content: content) {
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5, handler: nil)
        
        XCTAssert(chatProcessor.messages.count == 1)
        XCTAssert(chatProcessor.messages[0].sender == SenderName.human)
        XCTAssert(chatProcessor.messages[0].content == content)
    }
}
