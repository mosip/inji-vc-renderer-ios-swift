import XCTest
@testable import InjiVcRenderer
@testable import pixelpass




class InjiVcRendererTests: XCTestCase {
    
    private let BENEFITS_PLACEHOLDER_1 = "{{benefits1}}"
    private let BENEFITS_PLACEHOLDER_2 = "{{benefits2}}"
    let FULL_ADDRESS_PLACEHOLDER_1 = "{{fullAddress1}}"
    let FULL_ADDRESS_PLACEHOLDER_2 = "{{fullAddress2}}"

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
    
       private func createPlaceholders(for type: String) -> [String] {
           switch type {
           case "benefits":
               return [BENEFITS_PLACEHOLDER_1, BENEFITS_PLACEHOLDER_2]
           case "address":
               return [FULL_ADDRESS_PLACEHOLDER_1, FULL_ADDRESS_PLACEHOLDER_2]
           default:
               return []
           }
       }
       
       func testReplaceMultiLinePlaceholders() {
           let mockSession = MockURLSession()
           
           let renderer = InjiVcRenderer(session: mockSession)
           let svgTemplate = "<svg>{{fullAddress1}},{{fullAddress2}}</svg>"
           let dataToSplit = "TestData1TestData2TestData3"
           let maxLength = 10
           let placeholders = [FULL_ADDRESS_PLACEHOLDER_1, FULL_ADDRESS_PLACEHOLDER_2 ]

           let result = renderer.replaceMultiLinePlaceholders(svgTemplate: svgTemplate, dataToSplit: dataToSplit, maxLength: maxLength, placeholdersList: placeholders)

           let expected = "<svg>TestData1T,estData2Te</svg>"
           XCTAssertEqual(result, expected)
       }

       func testReplaceBenefits() {
           let mockSession = MockURLSession()
           
           let renderer = InjiVcRenderer(session: mockSession)
           let svgTemplate = "<svg>{{benefits1}},{{benefits2}}</svg>"
           let jsonObject: [String: Any] = [
               "credentialSubject": [
                   "benefits": ["Benefit1", "Benefit2", "Benefit3", "Benefit4", "Benefit5", "Benefit6", "Benefit7", "Benefit8", "Benefit9"]
               ]
           ]
           
           let result = renderer.replaceBenefits(jsonObject: jsonObject, svgTemplate: svgTemplate)

           let expected = "<svg>Benefit1,Benefit2,Benefit3,Benefit4,Benefit5,Benefit6,B,enefit7,Benefit8,Benefit9</svg>"
           XCTAssertEqual(result, expected)
       }

       func testReplaceAddress() {
           let mockSession = MockURLSession()
           
           let renderer = InjiVcRenderer(session: mockSession)
           let svgTemplate = "<svg>{{fullAddress1}}{{fullAddress2}}</svg>"
           let jsonObject: [String: Any] = [
               "credentialSubject": [
                   "addressLine1": [["value": "123 Main St, 123 Main St"]],
                   "addressLine2": [["value": "Suite 4B, Suite 4B"]],
                   "city": [["value": "Metropolis"]],
                   "province": [["value": "NY"]],
                   "postalCode": [["value": "12345"]]
               ]
           ]
           
           let result = renderer.replaceAddress(jsonObject: jsonObject, svgTemplate: svgTemplate)

           let expected = "<svg>123 Main St, 123 Main St,Suite 4B, Suite 4B,Metropolis,NY,12345</svg>"
           XCTAssertEqual(result, expected)
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
