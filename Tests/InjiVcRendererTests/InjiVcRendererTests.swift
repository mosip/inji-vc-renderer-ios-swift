import XCTest
@testable import InjiVcRenderer
@testable import pixelpass




class InjiVcRendererTests: XCTestCase {
    

    func testRenderSvgSuccess() async {
        let jsonString = """
        {
            "renderMethod": [
                { "id": "https://example.com/template.svg" }
            ],
            "credentialSubject" : {
                "fullName": "Tester",
                "gender": {
                    "eng": "Male"
                }
            }
        }
        """
        let templateContent = """
        <svg>
            <text>{{credentialSubject/fullName}}</text>
            <text>{{credentialSubject/gender}}</text>
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
        let result = await renderer.renderSvg(vcJsonString: jsonString)
        
        let expectedResult = """
        <svg>
            <text>Tester</text>
            <text>Male</text>
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
        let result = await renderer.renderSvg(vcJsonString: jsonString)
        
        XCTAssertEqual(result, "", "The result should be an empty string when fetching content fails")
    }
    
    func testRenderSvgFailureEmptyJsonString() async {
        let jsonString = """
        """
        
        let mockSession = MockURLSession()
        mockSession.mockError = NSError(domain: "Test", code: 1, userInfo: nil)
        
        let renderer = InjiVcRenderer(session: mockSession)
        let result = await renderer.renderSvg(vcJsonString: jsonString)
        
        XCTAssertEqual(result, "", "The result should be an empty string when fetching content fails")
    }
    
    func testLocaleBasedFieldReplacement() {
        
        let svgTemplateWithLocale = "<svg>{{credentialSubject/gender/eng}}</svg>"
        let svgTemplateWithoutLocale = "<svg>{{credentialSubject/gender}}</svg>"
        let svgTemplateWithUnavailableLocale = "<svg>{{credentialSubject/gender}}</svg>"
        let svgTemplateWithInvalidKey = "<svg>{{credentialSubject/gend}}</svg>"
        
        let processedJson = [
            "credentialSubject": [
              "gender": ["eng": "English Male", "tam": "Tamil Male"]
            ]
        ]
        
        let expected = "<svg>English Male</svg>"
        
        let result1 = InjiVcRenderer().replacePlaceholders(svgTemplate: svgTemplateWithLocale, processedJson: processedJson);
        XCTAssertEqual(result1, expected)
        
        let result2 = InjiVcRenderer().replacePlaceholders(svgTemplate: svgTemplateWithoutLocale, processedJson: processedJson);
        XCTAssertEqual(result2, expected)
        
        let result3 = InjiVcRenderer().replacePlaceholders(svgTemplate: svgTemplateWithUnavailableLocale, processedJson: processedJson);
        XCTAssertEqual(result3, expected)

        let result4 = InjiVcRenderer().replacePlaceholders(svgTemplate: svgTemplateWithInvalidKey, processedJson: processedJson);
        XCTAssertEqual(result4, "<svg></svg>")
        
        
    }
    
    func testAddressFieldsReplacement() {
        let svgTemplateWithLocale = "<svg>{{credentialSubject/fullAddressLine1/eng}}</svg>"
        let svgTemplateWithoutLocale = "<svg>{{credentialSubject/fullAddressLine1}}</svg>"
        let svgTemplateWithUnavailableLocale = "<svg>{{credentialSubject/fullAddressLine1/fr}}</svg>"

        let processedJson = [
            "credentialSubject": [
              "fullAddressLine1": ["eng": "Test Address1, Test City"]
            ]
        ]

        let result1 = InjiVcRenderer().replacePlaceholders(svgTemplate: svgTemplateWithLocale, processedJson: processedJson)
        XCTAssertEqual(result1, "<svg>Test Address1, Test City</svg>")
        
        let result2 = InjiVcRenderer().replacePlaceholders(svgTemplate: svgTemplateWithoutLocale, processedJson: processedJson)
        XCTAssertEqual(result2, "<svg>Test Address1, Test City</svg>")
        
        let result3 = InjiVcRenderer().replacePlaceholders(svgTemplate: svgTemplateWithUnavailableLocale, processedJson: processedJson)
        XCTAssertEqual(result3, "<svg>Test Address1, Test City</svg>")

    }
    
    func testAddressFieldsReplacementWithEmpty() {
        let svgTemplate = "<svg>{{credentialSubject/fullAddressLine1/eng}}</svg>"

        let processedJson = [
            "credentialSubject": [
              "fullAddressLine1": []
            ]
        ]

        let result1 = InjiVcRenderer().replacePlaceholders(svgTemplate: svgTemplate, processedJson: processedJson)
        XCTAssertEqual(result1, "<svg></svg>")

    }
    
    func testBenefitsFieldsReplacement() {
        let svgTemplate = "<svg>{{credentialSubject/benefitsLine1}}</svg>"

        let processedJson = [
            "credentialSubject": [
              "benefitsLine1": "Full body check up, Critical Surgery"
            ]
        ]

        let result1 = InjiVcRenderer().replacePlaceholders(svgTemplate: svgTemplate, processedJson: processedJson)
        XCTAssertEqual(result1, "<svg>Full body check up, Critical Surgery</svg>")

    }
    
    func testBenefitsFieldsReplacementWithEmpty() {
        let svgTemplate = "<svg>{{credentialSubject/benefitsLine1}}</svg>"

        let processedJson = [
            "credentialSubject": [
            ]
        ]

        let result1 = InjiVcRenderer().replacePlaceholders(svgTemplate: svgTemplate, processedJson: processedJson)
        XCTAssertEqual(result1, "<svg></svg>")

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
