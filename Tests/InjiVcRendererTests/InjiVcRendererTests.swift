import XCTest
@testable import InjiVcRenderer

// Mock URLSession
class MockURLSession: URLSession {
    var data: Data?
    var error: Error?

    override func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        let task = MockURLSessionDataTask {
            completionHandler(self.data, nil, self.error)
        }
        return task
    }
}

// Mock URLSessionDataTask
class MockURLSessionDataTask: URLSessionDataTask {
    private let closure: () -> Void

    init(closure: @escaping () -> Void) {
        self.closure = closure
    }

    override func resume() {
        closure()
    }
}

class InjiVcRendererTests: XCTestCase {
    var renderer: InjiVcRenderer!
    var mockSession: MockURLSession!

    override func setUp() {
        super.setUp()
        mockSession = MockURLSession()
        renderer = InjiVcRenderer(session: mockSession)
    }

    override func tearDown() {
        renderer = nil
        mockSession = nil
        super.tearDown()
    }

    // Test successful placeholder replacement
    func testRenderSvgSuccess() {
        // Define the JSON string with placeholders and data
        let jsonString = """
        {
            "renderMethod": [
                {
                    "id": "http://example.com/template"
                }
            ],
            "user": {
                "name": "John Doe",
                "joinDate": "2024-01-15T10:00:00Z"
            }
        }
        """
        
        // Define the expected template and output
        let expectedTemplate = """
        Hello, {{user/name}}! You joined on {{user/joinDate}}.
        """
        let expectedOutput = "Hello, John Doe! You joined on 2024/01/15."
        
        // Set up the mock session to return the expected template
        mockSession.data = expectedTemplate.data(using: .utf8)

        let expectation = self.expectation(description: "Completion handler invoked")
        var result: String?

        renderer.renderSvg(from: jsonString) { output in
            result = output
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1.0) { error in
            if let error = error {
                XCTFail("Expectation failed with error: \(error)")
            }
            // Print result for debugging
            print("Result: \(String(describing: result))")
            print("Expected Output: \(expectedOutput)")
        }

        XCTAssertEqual(result, expectedOutput)
    }

    // Test handling of invalid JSON
    func testRenderSvgInvalidJSON() {
        let jsonString = "invalid json"
        let expectation = self.expectation(description: "Completion handler invoked")
        var result: String?

        renderer.renderSvg(from: jsonString) { output in
            result = output
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1.0, handler: nil)
        XCTAssertNil(result)
    }

    // Test handling of invalid template URL
    func testRenderSvgInvalidTemplateURL() {
        let jsonString = """
        {
            "renderMethod": [
                {
                    "id": "invalid-url"
                }
            ]
        }
        """
        let expectation = self.expectation(description: "Completion handler invoked")
        var result: String?

        renderer.renderSvg(from: jsonString) { output in
            result = output
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1.0, handler: nil)
        XCTAssertNil(result)
    }

    // Test date formatting
    func testDateFormatting() {
        let dateString = "2024-01-15T10:00:00Z"
        let formattedDate = renderer.formatDateString(dateString)
        XCTAssertEqual(formattedDate, "2024/01/15")
    }

    // Test invalid date format
    func testInvalidDateFormatting() {
        let dateString = "invalid-date"
        let formattedDate = renderer.formatDateString(dateString)
        XCTAssertNil(formattedDate)
    }
}
