import Foundation
import pixelpass

public struct InjiVcRenderer {
    
    private let session: URLSession
    private let QRCODE_IMAGE_TYPE = "data:image/png;base64,"
    private let QRCODE_PLACEHOLDER = "{{qrCodeImage}}"
    private let PLACEHOLDER_REGEX_PATTERN = "\\{\\{([^}]+)\\}\\}"
    
    private let BENEFITS_PLACEHOLDER_1 = "{{benefits1}}"
    private let BENEFITS_PLACEHOLDER_2 = "{{benefits2}}"
    let FULL_ADDRESS_PLACEHOLDER_1 = "{{fullAddress1}}"
    let FULL_ADDRESS_PLACEHOLDER_2 = "{{fullAddress2}}"
    
    public init(session: URLSession = .shared) {
        self.session = session
    }
    
    public func renderSvg(from jsonString: String) async -> String {
        guard let values = jsonStringToDictionary(jsonString),
              let templateURL = extractTemplateURL(from: values) else {
            print("Invalid JSON or template URL")
            return ""
        }
        do {
            var template = try await fetchString(from: templateURL)
            
            if let base64String = replaceQRCode(jsonString) {
                template = template.replacingOccurrences(of: QRCODE_PLACEHOLDER, with: base64String)
            }
            
            template = replaceBenefits(jsonObject: values, svgTemplate: template)
            
            template = replaceAddress(jsonObject: values, svgTemplate: template)
            
            // Replace other placeholders
            template = replacePlaceholders(in: template, with: values)
            
            return template
        } catch {
            print("Failed to fetch content: \(error)")
            return ""
        }
    }
    
    public func replaceMultiLinePlaceholders(svgTemplate: String,
                                              dataToSplit: String,
                                              maxLength: Int,
                                              placeholdersList: [String]) -> String {
        do {
            let segments = dataToSplit.chunked(into: maxLength).prefix(2)
            var replacedSvg = svgTemplate
            for (index, placeholder) in placeholdersList.enumerated() {
                if index < segments.count {
                    replacedSvg = replacedSvg.replacingOccurrences(of: placeholder, with: segments[index], options: .literal, range: replacedSvg.range(of: placeholder))
                }
            }
            return replacedSvg
        } catch {
            print("Error replacing placeholders: \(error)")
            return svgTemplate
        }
    }
    
    
    public func replaceBenefits(jsonObject: [String: Any], svgTemplate: String) -> String {
        do {
            guard let credentialSubject = jsonObject["credentialSubject"] as? [String: Any],
                  let benefitsArray = credentialSubject["benefits"] as? [String] else {
                return svgTemplate
            }
            
            let benefitsString = benefitsArray.joined(separator: ",")
            let benefitsPlaceholderList = [BENEFITS_PLACEHOLDER_1, BENEFITS_PLACEHOLDER_2]
            let replacedSvgWithBenefits = replaceMultiLinePlaceholders(svgTemplate: svgTemplate, dataToSplit: benefitsString, maxLength: 55, placeholdersList: benefitsPlaceholderList)
            
            return replacedSvgWithBenefits
        } catch {
            print("Error replacing benefits: \(error)")
            return svgTemplate
        }
    }
    
    public func replaceAddress(jsonObject: [String: Any], svgTemplate: String) -> String {
        do {
            guard let credentialSubject = jsonObject["credentialSubject"] as? [String: Any] else {
                return svgTemplate
            }
            
            let fields = ["addressLine1", "addressLine2", "addressLine3", "city", "province", "region", "postalCode"]
            var values = [String]()
            
            for field in fields {
                if let array = credentialSubject[field] as? [[String: Any]], let value = array.first?["value"] as? String, !value.trimmingCharacters(in: .whitespaces).isEmpty {
                    values.append(value.trimmingCharacters(in: .whitespaces))
                }
            }
            
            let fullAddress = values.joined(separator: ",")
            let addressPlaceholderList = [FULL_ADDRESS_PLACEHOLDER_1, FULL_ADDRESS_PLACEHOLDER_2]
            let replacedSvgWithFullAddress = replaceMultiLinePlaceholders(svgTemplate: svgTemplate, dataToSplit: fullAddress, maxLength: 55, placeholdersList: addressPlaceholderList)
            
            return replacedSvgWithFullAddress
        } catch {
            print("Error replacing address: \(error)")
            return svgTemplate
        }
    }
    
    private func fetchString(from urlString: String) async throws -> String {
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        let request = URLRequest(url: url)
        return try await withCheckedThrowingContinuation { continuation in
            let task = session.dataTask(with: request) { data, response, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let data = data, let response = response else {
                    continuation.resume(throwing: URLError(.unknown))
                    return
                }
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    continuation.resume(throwing: URLError(.badServerResponse))
                    return
                }
                guard let string = String(data: data, encoding: .utf8) else {
                    continuation.resume(throwing: URLError(.cannotParseResponse))
                    return
                }
                continuation.resume(returning: string)
            }
            task.resume()
        }
    }
    
    private func extractTemplateURL(from values: [String: Any]) -> String? {
        guard let renderMethodArray = values["renderMethod"] as? [[String: Any]],
              let firstRenderMethod = renderMethodArray.first,
              let urlString = firstRenderMethod["id"] as? String else {
            return nil
        }
        return urlString
    }
    
    private func jsonStringToDictionary(_ jsonString: String) -> [String: Any]? {
        if let data = jsonString.data(using: .utf8) {
            do {
                let dictionary = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                return dictionary
            } catch {
                print("Error deserializing JSON: \(error)")
            }
        }
        return nil
    }
    
    private func replaceQRCode(_ vcJson: String) -> String? {
        let pixelPass = PixelPass()
        if let qrCodeData = pixelPass.generateQRCode(data: vcJson,  ecc: .M, header: "HDR") {
            let base64String = QRCODE_IMAGE_TYPE + qrCodeData.base64EncodedString()
            return base64String
        }
        return nil
    }
    
    private func replacePlaceholders(in template: String, with values: [String: Any]) -> String {
        var result = template
        let regex: NSRegularExpression
        do {
            regex = try NSRegularExpression(pattern: PLACEHOLDER_REGEX_PATTERN, options: [])
        } catch {
            print("Invalid regular expression pattern: \(error)")
            return template
        }
        
        let matches = regex.matches(in: template, options: [], range: NSRange(location: 0, length: template.utf16.count))
        for match in matches.reversed() {
            if let range = Range(match.range(at: 1), in: template) {
                let key = String(template[range])
                let value = resolvePlaceholder(key, in: values) ?? ""
                result = result.replacingOccurrences(of: "{{\(key)}}", with: value)
            }
        }
        return result
    }

    private func resolvePlaceholder(_ key: String, in values: [String: Any]) -> String? {
        let components = key.split(separator: "/").map(String.init)
        var value: Any? = values
        
        for (index, component) in components.enumerated() {
            if let array = value as? [Any], let index = Int(component), index < array.count {
                value = array[index]
            } else {
                value = (value as? [String: Any])?[component]
            }
            
            if value == nil {
                return nil
            }
        }
        
        if let value = value as? String {
            return value
        } else if let value = value as? [String: Any], let firstValue = value.first?.value as? String {
            return firstValue
        }
        return nil
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
