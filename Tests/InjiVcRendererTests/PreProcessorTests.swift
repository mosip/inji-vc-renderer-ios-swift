import XCTest
import Foundation
import InjiVcRenderer

class PreProcessorTests: XCTestCase {
    
    let templatePreProcessor = PreProcessor()
    func testLocaleBasedFields() {
        let vcJsonString = """
        {
            "credentialSubject": {
                "gender": [
                    {
                        "language": "eng",
                        "value": "English Male"
                    },
                    {
                        "language": "tam",
                        "value": "Tamil Male"
                    }
                ]
            }
        }
        """
        let svgTemplate = "{{credentialSubject/gender/eng}}"

        let expected: [String: Any] = [
              "credentialSubject": [
                "gender": ["eng": "English Male", "tam": "Tamil Male"]
              ]
          ]

        let result = templatePreProcessor.preProcessVcJson(vcJsonString: vcJsonString, svgTemplate: svgTemplate)

        XCTAssertEqual(result as NSDictionary, expected as NSDictionary, "Locale based Json did not match the expected result")
    }
    
    func testAddressFields() {
        let vcJsonString = """
        {
                    "credentialSubject": {
                        "addressLine1": [
                            {
                                "language": "eng",
                                "value": "Address Line 1"
                            },
                            {
                                "language": "fr",
                                "value": "Address Line1 French"
                            }
                        ],
                        "city": [
                            {
                                "language": "eng",
                                "value": "City"
                            },
                            {
                                "language": "fr",
                                "value": "City French"
                            }
                        ]
                    }
                }
        """
        let svgTemplate = "{{credentialSubject/fullAddressLine1/eng}}"

        let expected: [String: Any] = [
              "credentialSubject": [
                "fullAddressLine1": ["eng": "Address Line 1, City"]
              ]
          ]

        let result = templatePreProcessor.preProcessVcJson(vcJsonString: vcJsonString, svgTemplate: svgTemplate)

        XCTAssertEqual(result as NSDictionary, expected as NSDictionary, "Address Json did not match the expected result")
    }
    
    func testBenefitsFields() {
        let vcJsonString = """
        {
                    "credentialSubject": {
                        "benefits": [ "Benefits one, Benefits two"
                        ]
                    }
                }
        """
        let svgTemplate = "{{credentialSubject/benefitsLine1}}"

        let expected: [String: Any] = [
              "credentialSubject": [
                "benefitsLine1": "Benefits one, Benefits two"
              ]
          ]

        let result = templatePreProcessor.preProcessVcJson(vcJsonString: vcJsonString, svgTemplate: svgTemplate)

        XCTAssertEqual(result as NSDictionary, expected as NSDictionary, "Benefits Json did not match the expected result")
    }
    
    
    func testGetFieldNameFromPlaceholder() {
        let placeholder = "{{credentialSubject/qrCodeImage}}"
        
        let result = templatePreProcessor.getFieldNameFromPlaceholder(placeholder)
        XCTAssertEqual(result, "qrCodeImage", "QR code placeholder not mathcing")
        
        let placeholder1 = "{{credentialSubject/fullAddressLine1/eng}}"
        
        let result1 = templatePreProcessor.getFieldNameFromPlaceholder(placeholder1)
        XCTAssertEqual(result1, "fullAddressLine1")
        
        let placeholder2 = "{{credentialSubject/benefitsLine1}}"
        
        let result2 = templatePreProcessor.getFieldNameFromPlaceholder(placeholder2)
        XCTAssertEqual(result2, "benefitsLine1")
        
        
        
    }
    
    func testGetFieldNameFromPlaceholderFailureRegexNotMatching() {
        let placeholder = "{{credentialSubject/qrCodeImage"
        
        let result = templatePreProcessor.getFieldNameFromPlaceholder(placeholder)
        XCTAssertEqual(result, "", "Regex Not matching")
        
    }
    
    func testExtractLanguageFromPlaceholder() {
        
        let placeholder1 = "{{credentialSubject/fullAddressLine1/eng}}"
        
        let result1 = templatePreProcessor.extractLanguageFromPlaceholder(placeholder1)
        XCTAssertEqual(result1, "eng")
        
        let placeholder2 = "{{credentialSubject/benefitsLine1}}"
        
        let result2 = templatePreProcessor.extractLanguageFromPlaceholder(placeholder2)
        XCTAssertEqual(result2, "")
        
    }
    
    func testExtractLanguageFromPlaceholderFailureRegexNotMatching() {
        let placeholder = "{{credentialSubject/fullAddressLine1/eng"
        
        let result = templatePreProcessor.getFieldNameFromPlaceholder(placeholder)
        XCTAssertEqual(result, "", "Regex Not matching")
        
    }
    
    func testGetPlaceholdersListSuccess_AddressLine(){
        let svgTemplate = "<svg>{{credentialSubject/fullAddressLine1/eng}},{{credentialSubject/fullAddressLine2/eng}}</svg>"
        let pattern = PreProcessor.FULL_ADDRESS_PLACEHOLDER_REGEX_PATTERN
        let result = templatePreProcessor.getPlaceholdersList(pattern: pattern, svgTemplate: svgTemplate)
        
        XCTAssertEqual(result, ["{{credentialSubject/fullAddressLine1/eng}}", "{{credentialSubject/fullAddressLine2/eng}}"], "Address Line Placeholder list found")
    }
    
    func testGetPlaceholdersListSuccess_BenefitsLine(){
        let svgTemplate = "<svg>{{credentialSubject/benefitsLine1}},{{credentialSubject/benefitsLine2}}</svg>"
        let pattern = PreProcessor.BENEFITS_PLACEHOLDER_REGEX_PATTERN
        let result = templatePreProcessor.getPlaceholdersList(pattern: pattern, svgTemplate: svgTemplate)
        
        XCTAssertEqual(result, ["{{credentialSubject/benefitsLine1}}", "{{credentialSubject/benefitsLine2}}"], "Benefits Line Placeholder list found")
    }
    
    func testGetPlaceholdersList_BenefitsLine_Not_Found(){
        let svgTemplate = "<svg>{{credentialSubject/benefitsLine}},{{credentialSubject/benefitsLine}}</svg>"
        let pattern = PreProcessor.BENEFITS_PLACEHOLDER_REGEX_PATTERN
        let result = templatePreProcessor.getPlaceholdersList(pattern: pattern, svgTemplate: svgTemplate)
        
        XCTAssertEqual(result, [], "Benefits Line Placeholder list not found/invalid")
    }
    
    func testGetPlaceholdersList_AddressLine_Not_Found(){
        let svgTemplate = "<svg>{{credentialSubject/fullAddressLine/eng}},{{credentialSubject/fullAddressLin}}</svg>"
        let pattern = PreProcessor.FULL_ADDRESS_PLACEHOLDER_REGEX_PATTERN
        let result = templatePreProcessor.getPlaceholdersList(pattern: pattern, svgTemplate: svgTemplate)
        
        XCTAssertEqual(result, [], "Address Line Placeholder list not found/invalid")
    }
}

enum JSONError: Error {
    case invalidData
    case parsingError
}
