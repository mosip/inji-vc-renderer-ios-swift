import Foundation
import pixelpass

public class PreProcessor {
    
    public init() {}
    
    private let QRCODE_IMAGE_TYPE = "data:image/png;base64,"

    public func preProcessVcJson(vcJsonString: String, svgTemplate: String) -> [String: Any] {
        
        guard let data = vcJsonString.data(using: .utf8),
              var vcJsonObject = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
              var credentialSubject = vcJsonObject["credentialSubject"] as? [String: Any] else {
            return [:]
        }

        credentialSubject = replaceFieldsWithLanguage(credentialSubject)

        // Check for {{qrCodeImage}} for QR Code Replacement
        if svgTemplate.contains(PreProcessor.QR_CODE_PLACEHOLDER) {
            let qrCodeImage = replaceQRCode(vcJsonString)
            credentialSubject[getFieldNameFromPlaceholder(PreProcessor.QR_CODE_PLACEHOLDER)] = qrCodeImage
        }

        // Check for benefits placeholders
        let benefitsPlaceholderRegexPattern = PreProcessor.BENEFITS_PLACEHOLDER_REGEX_PATTERN
        if svgTemplate.range(of: benefitsPlaceholderRegexPattern, options: .regularExpression) != nil {
            let benefitsPlaceholders = getPlaceholdersList(pattern: benefitsPlaceholderRegexPattern, svgTemplate: svgTemplate)
            let language = extractLanguageFromPlaceholder(benefitsPlaceholders.first ?? "")
            let commaSeparatedBenefits = generateCommaSeparatedString(jsonObject: credentialSubject, fieldsToBeCombined: [PreProcessor.BENEFITS_FIELD_NAME], language: language)

            credentialSubject = constructObjectBasedOnCharacterLengthChunks(dataToSplit: commaSeparatedBenefits, placeholderList: benefitsPlaceholders, maxCharacterLength: PreProcessor.MAXIMUM_CHARACTER_PER_LINE, credentialSubject: credentialSubject, language: language)

            for fieldName in [PreProcessor.BENEFITS_FIELD_NAME] {
                credentialSubject.removeValue(forKey: fieldName)
            }
        }

        // Check for full address placeholders
        let fullAddressRegexPattern = PreProcessor.FULL_ADDRESS_PLACEHOLDER_REGEX_PATTERN
        if svgTemplate.range(of: fullAddressRegexPattern, options: .regularExpression) != nil {
            let addressFields = [PreProcessor.ADDRESS_LINE_1, PreProcessor.ADDRESS_LINE_2, PreProcessor.ADDRESS_LINE_3, PreProcessor.CITY, PreProcessor.PROVINCE, PreProcessor.POSTAL_CODE, PreProcessor.REGION]
            let fullAddressPlaceholders = getPlaceholdersList(pattern: fullAddressRegexPattern, svgTemplate: svgTemplate)
            let language = extractLanguageFromPlaceholder(fullAddressPlaceholders.first ?? "")
            let commaSeparatedAddress = generateCommaSeparatedString(jsonObject: credentialSubject, fieldsToBeCombined: addressFields, language: language)

            credentialSubject = constructObjectBasedOnCharacterLengthChunks(dataToSplit: commaSeparatedAddress, placeholderList: fullAddressPlaceholders, maxCharacterLength: PreProcessor.MAXIMUM_CHARACTER_PER_LINE, credentialSubject: credentialSubject, language: language)

            for fieldName in addressFields {
                credentialSubject.removeValue(forKey: fieldName)
            }
        }

        vcJsonObject["credentialSubject"] = credentialSubject
        return vcJsonObject
    }

    private func replaceFieldsWithLanguage(_ jsonObject: [String: Any]) -> [String: Any] {
        var updatedJsonObject = jsonObject

        for (key, value) in jsonObject {
            if let arrayValue = value as? [[String: Any]] {
                var languageMap = [String: String]()
                for item in arrayValue {
                    if let language = item["language"] as? String, let newValue = item["value"] as? String {
                        languageMap[language] = newValue
                    }
                }
                if !languageMap.isEmpty {
                    updatedJsonObject[key] = languageMap
                }
            } else if let nestedObject = value as? [String: Any] {
                updatedJsonObject[key] = replaceFieldsWithLanguage(nestedObject)
            }
        }

        return updatedJsonObject
    }

    public func getFieldNameFromPlaceholder(_ placeholder: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: PreProcessor.GET_PLACEHOLDER_REGEX, options: []) else {
            return ""
        }
        
        let nsRange = NSRange(location: 0, length: placeholder.utf16.count)
        if let match = regex.firstMatch(in: placeholder, options: [], range: nsRange) {
            let range = match.range(at: 1)
            if range.location != NSNotFound {
                let enclosedValue = (placeholder as NSString).substring(with: range)
                return enclosedValue.split(separator: "/").last.map(String.init) ?? ""
            }
        }
        return ""
    }

    public func extractLanguageFromPlaceholder(_ placeholder: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: PreProcessor.GET_LANGUAGE_FORM_PLACEHOLDER_REGEX, options: []) else {
            return ""
        }
        
        let nsRange = NSRange(location: 0, length: placeholder.utf16.count)
        if let match = regex.firstMatch(in: placeholder, options: [], range: nsRange) {
            let range = match.range(at: 1)
            if range.location != NSNotFound {
                return (placeholder as NSString).substring(with: range)
            }
        }
        return ""
    }
    
    public func getPlaceholdersList(pattern: String, svgTemplate: String) -> [String] {
        var placeholders = [String]()

        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return placeholders
        }
        let matches = regex.matches(in: svgTemplate, options: [], range: NSRange(location: 0, length: svgTemplate.utf16.count))

        for match in matches {
            if let range = Range(match.range, in: svgTemplate) {
                let placeholder = String(svgTemplate[range])
                placeholders.append(placeholder)
            }
        }
        return placeholders
    }

    private func replaceQRCode(_ vcJson: String) -> String? {
        let pixelPass = PixelPass()
        if let qrCodeData = pixelPass.generateQRCode(data: vcJson,  ecc: .M, header: "HDR") {
            let base64String = QRCODE_IMAGE_TYPE + qrCodeData.base64EncodedString()
            return base64String
        }
        return nil
    }

    
    private func generateCommaSeparatedString(jsonObject: [String: Any], fieldsToBeCombined: [String], language: String) -> String {
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

    private func constructObjectBasedOnCharacterLengthChunks(dataToSplit: String, placeholderList: [String], maxCharacterLength: Int, credentialSubject: [String: Any], language: String) -> [String: Any] {
        var updatedCredentialSubject = credentialSubject
        let segments = dataToSplit.chunked(into: maxCharacterLength).prefix(placeholderList.count)

        for (index, placeholder) in placeholderList.enumerated() {
            if index < segments.count {
                let languageSpecificData: Any = language.isEmpty ? segments[index] : [language: segments[index]]
                updatedCredentialSubject[getFieldNameFromPlaceholder(placeholder)] = languageSpecificData
            }
        }
        return updatedCredentialSubject
    }
}

extension String {
    func chunked(into size: Int) -> [String] {
        guard size > 0 else { return [] }
        return stride(from: 0, to: count, by: size).map {
            let start = index(startIndex, offsetBy: $0)
            let end = index(start, offsetBy: size, limitedBy: endIndex) ?? endIndex
            return String(self[start..<end])
        }
    }
}

extension PreProcessor {
    static let CREDENTIAL_SUBJECT_FIELD = "credentialSubject"
    static let QR_CODE_PLACEHOLDER = "{{credentialSubject/qrCodeImage}}"
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
    static let GET_PLACEHOLDER_REGEX = "\\{\\{credentialSubject/([^/]+)(?:/[^}]+)?\\}\\}"
    static let GET_LANGUAGE_FORM_PLACEHOLDER_REGEX = "credentialSubject/[^/]+/(\\w+)"
    static let MAXIMUM_CHARACTER_PER_LINE = 55
}
