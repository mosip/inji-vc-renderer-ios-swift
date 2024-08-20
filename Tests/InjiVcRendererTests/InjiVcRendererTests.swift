import XCTest
@testable import InjiVcRenderer



class InjiVcRendererTests: XCTestCase {

    func testRenderSvgSuccess() async {
        let jsonString = """
        {
            "renderMethod": [
                { "id": "https://example.com/template.svg" }
            ],
            "key1": "value1",
            "key2": {
                "nestedKey": "nestedValue"
            }
        }
        """
        let templateContent = """
        <svg>
            <text>{{key1}}</text>
            <text>{{key2/nestedKey}}</text>
        </svg>
        """
        
        let mockData = templateContent.data(using: .utf8)
        let mockResponse = HTTPURLResponse(url: URL(string: "https://example.com/template.svg")!,
                                           statusCode: 200,
                                           httpVersion: nil,
                                           headerFields: nil)
        let mockSession = MockURLSession()
        mockSession.mockData = mockData
        mockSession.mockResponse = mockResponse
        
        let renderer = InjiVcRenderer(session: mockSession)
        let result = await renderer.renderSvg(from: jsonString)
        
        let expectedResult = """
        <svg>
            <text>value1</text>
            <text>nestedValue</text>
        </svg>
        """
        
        XCTAssertEqual(result, expectedResult, "The rendered SVG did not match the expected result")
    }
    
    func testRenderSvgFailure() async {
        let jsonString = """
        {
            "renderMethod": [
                { "id": "https://example.com/template.svg" }
            ]
        }
        """
        
        let mockSession = MockURLSession()
        mockSession.mockError = NSError(domain: "Test", code: 1, userInfo: nil)
        
        let renderer = InjiVcRenderer(session: mockSession)
        let result = await renderer.renderSvg(from: jsonString)
        
        XCTAssertEqual(result, "", "The result should be an empty string when fetching content fails")
    }
}

class MockURLSession: URLSession {
    var mockData: Data?
    var mockResponse: URLResponse?
    var mockError: Error?

    override func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        return MockURLSessionDataTask {
            completionHandler(self.mockData, self.mockResponse, self.mockError)
        }
    }
}

class MockURLSessionDataTask: URLSessionDataTask {
    private let closure: () -> Void

    init(closure: @escaping () -> Void) {
        self.closure = closure
    }

    override func resume() {
        closure()
    }
}
