import Foundation

public class Utils {
    public static func extractLanguageFromPlaceholder(_ placeholder: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: Utils.GET_LANGUAGE_FORM_PLACEHOLDER_REGEX, options: []) else {
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
    
    public static func getPlaceholdersList(pattern: String, svgTemplate: String) -> [String] {
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
    
    public static func getFieldNameFromPlaceholder(_ placeholder: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: Utils.GET_PLACEHOLDER_REGEX, options: []) else {
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
}

extension Utils {
    static let GET_PLACEHOLDER_REGEX = "\\{\\{credentialSubject/([^/]+)(?:/[^}]+)?\\}\\}"
    static let GET_LANGUAGE_FORM_PLACEHOLDER_REGEX = "credentialSubject/[^/]+/(\\w+)"
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
