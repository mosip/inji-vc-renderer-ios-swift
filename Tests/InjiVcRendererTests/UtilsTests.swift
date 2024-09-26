import Foundation
import XCTest
import InjiVcRenderer

class UtilsTests: XCTestCase {
    
    
    func testGetFieldNameFromPlaceholder() {
        let placeholder = "{{credentialSubject/qrCodeImage}}"
        
        let result = Utils.getFieldNameFromPlaceholder(placeholder)
        XCTAssertEqual(result, "qrCodeImage", "QR code placeholder not mathcing")
        
        let placeholder1 = "{{credentialSubject/fullAddressLine1/eng}}"
        
        let result1 = Utils.getFieldNameFromPlaceholder(placeholder1)
        XCTAssertEqual(result1, "fullAddressLine1")
        
        let placeholder2 = "{{credentialSubject/benefitsLine1}}"
        
        let result2 = Utils.getFieldNameFromPlaceholder(placeholder2)
        XCTAssertEqual(result2, "benefitsLine1")
        
        
        
    }
    
    func testGetFieldNameFromPlaceholderFailureRegexNotMatching() {
        let placeholder = "{{credentialSubject/qrCodeImage"
        
        let result = Utils.getFieldNameFromPlaceholder(placeholder)
        XCTAssertEqual(result, "", "Regex Not matching")
        
    }
    
    func testExtractLanguageFromPlaceholder() {
        
        let placeholder1 = "{{credentialSubject/fullAddressLine1/eng}}"
        
        let result1 = Utils.extractLanguageFromPlaceholder(placeholder1)
        XCTAssertEqual(result1, "eng")
        
        let placeholder2 = "{{credentialSubject/benefitsLine1}}"
        
        let result2 = Utils.extractLanguageFromPlaceholder(placeholder2)
        XCTAssertEqual(result2, "")
        
    }
    
    func testExtractLanguageFromPlaceholderFailureRegexNotMatching() {
        let placeholder = "{{credentialSubject/fullAddressLine1/eng"
        
        let result = Utils.getFieldNameFromPlaceholder(placeholder)
        XCTAssertEqual(result, "", "Regex Not matching")
        
    }
    
    func testGetPlaceholdersListSuccess_AddressLine(){
        let svgTemplate = "<svg>{{credentialSubject/fullAddressLine1/eng}},{{credentialSubject/fullAddressLine2/eng}}</svg>"
        let pattern = MultiLineHandler.FULL_ADDRESS_PLACEHOLDER_REGEX_PATTERN
        let result = Utils.getPlaceholdersList(pattern: pattern, svgTemplate: svgTemplate)
        
        XCTAssertEqual(result, ["{{credentialSubject/fullAddressLine1/eng}}", "{{credentialSubject/fullAddressLine2/eng}}"], "Address Line Placeholder list found")
    }
    
    func testGetPlaceholdersListSuccess_BenefitsLine(){
        let svgTemplate = "<svg>{{credentialSubject/benefitsLine1}},{{credentialSubject/benefitsLine2}}</svg>"
        let pattern = MultiLineHandler.BENEFITS_PLACEHOLDER_REGEX_PATTERN
        let result = Utils.getPlaceholdersList(pattern: pattern, svgTemplate: svgTemplate)
        
        XCTAssertEqual(result, ["{{credentialSubject/benefitsLine1}}", "{{credentialSubject/benefitsLine2}}"], "Benefits Line Placeholder list found")
    }
    
    func testGetPlaceholdersList_BenefitsLine_Not_Found(){
        let svgTemplate = "<svg>{{credentialSubject/benefitsLine}},{{credentialSubject/benefitsLine}}</svg>"
        let pattern = MultiLineHandler.BENEFITS_PLACEHOLDER_REGEX_PATTERN
        let result = Utils.getPlaceholdersList(pattern: pattern, svgTemplate: svgTemplate)
        
        XCTAssertEqual(result, [], "Benefits Line Placeholder list not found/invalid")
    }
    
    func testGetPlaceholdersList_AddressLine_Not_Found(){
        let svgTemplate = "<svg>{{credentialSubject/fullAddressLine/eng}},{{credentialSubject/fullAddressLin}}</svg>"
        let pattern = MultiLineHandler.FULL_ADDRESS_PLACEHOLDER_REGEX_PATTERN
        let result = Utils.getPlaceholdersList(pattern: pattern, svgTemplate: svgTemplate)
        
        XCTAssertEqual(result, [], "Address Line Placeholder list not found/invalid")
    }
}
