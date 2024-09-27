import Foundation

public class MultiLineHandler{
    
    
    public init() {}
    
    public func handleMultiLineFields(credentialSubject: [String : Any], svgTemplate: String) -> [String: Any] {

        var mutableCredentialSubject = credentialSubject
        
        // Handling full address placeholders
        let addressFields = [MultiLineHandler.ADDRESS_LINE_1,
                             MultiLineHandler.ADDRESS_LINE_2,
                             MultiLineHandler.ADDRESS_LINE_3,
                             MultiLineHandler.CITY,
                             MultiLineHandler.PROVINCE,
                             MultiLineHandler.POSTAL_CODE,
                             MultiLineHandler.REGION]
        mutableCredentialSubject = updateArrayOfFieldsInCredentialSubjectObject(regexPattern: MultiLineHandler.FULL_ADDRESS_PLACEHOLDER_REGEX_PATTERN,
                                                                                    svgTemplate: svgTemplate,
                                                                                        credentialSubject: mutableCredentialSubject,
                                                                                            maxCharacterPerLine: MultiLineHandler.MAXIMUM_CHARACTER_PER_LINE,
                                                                                                fieldsToBeCombined: addressFields)
        
        // Handling benefits placeholders
        mutableCredentialSubject = updateArrayOfFieldsInCredentialSubjectObject(regexPattern: MultiLineHandler.BENEFITS_PLACEHOLDER_REGEX_PATTERN, 
                                                                                    svgTemplate: svgTemplate,
                                                                                        credentialSubject: mutableCredentialSubject,
                                                                                            maxCharacterPerLine: MultiLineHandler.MAXIMUM_CHARACTER_PER_LINE,
                                                                                                fieldsToBeCombined: [MultiLineHandler.BENEFITS_FIELD_NAME])
        
        
        return mutableCredentialSubject
        
    }
    
    private func updateArrayOfFieldsInCredentialSubjectObject(regexPattern: String, 
                                                                svgTemplate: String,
                                                                    credentialSubject: [String:Any],
                                                                        maxCharacterPerLine: Int,
                                                                            fieldsToBeCombined: [String]) -> [String: Any] {
        var processedCredentialSubject = credentialSubject
        
        if svgTemplate.range(of: regexPattern, options: .regularExpression) != nil {

            let placeholders = Utils.getPlaceholdersList(pattern: regexPattern, svgTemplate: svgTemplate)
            let language = Utils.extractLanguageFromPlaceholder(placeholders.first ?? "")
            let commaSeparatedAddress = generateCommaSeparatedString(jsonObject: credentialSubject, 
                                                                        fieldsToBeCombined: fieldsToBeCombined,
                                                                            language: language)
            
            processedCredentialSubject = constructObjectBasedOnCharacterLengthChunks(dataToSplit: commaSeparatedAddress, 
                                                                                     placeholderList: placeholders,
                                                                                        maxCharacterLength: MultiLineHandler.MAXIMUM_CHARACTER_PER_LINE,
                                                                                            credentialSubject: credentialSubject,
                                                                                                language: language)
            
            for fieldName in fieldsToBeCombined {
                processedCredentialSubject.removeValue(forKey: fieldName)
            }
        }
        return processedCredentialSubject
    }
        
    private func generateCommaSeparatedString(jsonObject: [String: Any], 
                                                fieldsToBeCombined: [String],
                                                    language: String) -> String {
        return fieldsToBeCombined.flatMap { field in
            if let arrayField = jsonObject[field] as? [String] {
                return arrayField.filter { !$0.isEmpty }
            } else if let dictField = jsonObject[field] as? [String: Any], let langValue = dictField[language] as? String, !langValue.isEmpty {
                return [langValue]
            }
            return []
        }
        .filter { !$0.isEmpty }
        .joined(separator: ", ")
    }

    private func constructObjectBasedOnCharacterLengthChunks(dataToSplit: String, 
                                                                placeholderList: [String],
                                                                    maxCharacterLength: Int,
                                                                        credentialSubject: [String: Any],
                                                                            language: String) -> [String: Any] {
        var updatedCredentialSubject = credentialSubject
        let segments = dataToSplit.chunked(into: maxCharacterLength).prefix(placeholderList.count)

        for (index, placeholder) in placeholderList.enumerated() {
            if index < segments.count {
                let languageSpecificData: Any = language.isEmpty ? segments[index] : [language: segments[index]]
                updatedCredentialSubject[Utils.getFieldNameFromPlaceholder(placeholder)] = languageSpecificData
            }
        }
        return updatedCredentialSubject
    }
    
    
}

extension MultiLineHandler {
    static let BENEFITS_FIELD_NAME = "benefits"
    public static let BENEFITS_PLACEHOLDER_REGEX_PATTERN = "\\{\\{credentialSubject/benefitsLine\\d+\\}\\}"
    
    public static let FULL_ADDRESS_PLACEHOLDER_REGEX_PATTERN = "\\{\\{credentialSubject/fullAddressLine\\d+/[a-zA-Z]+\\}\\}"
    static let ADDRESS_LINE_1 = "addressLine1"
    static let ADDRESS_LINE_2 = "addressLine2"
    static let ADDRESS_LINE_3 = "addressLine3"
    static let CITY = "city"
    static let PROVINCE = "province"
    static let REGION = "region"
    static let POSTAL_CODE = "postalCode"

    static let MAXIMUM_CHARACTER_PER_LINE = 55
}
