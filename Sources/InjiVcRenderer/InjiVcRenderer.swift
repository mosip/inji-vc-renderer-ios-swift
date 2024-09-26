import Foundation
import pixelpass

public struct InjiVcRenderer {
    
    private let session: URLSession
    private let QRCODE_IMAGE_TYPE = "data:image/png;base64,"
    private let QRCODE_PLACEHOLDER = "{{qrCodeImage}}"
    private let PLACEHOLDER_REGEX_PATTERN = "\\{\\{([^}]+)\\}\\}"
    
    private let DEFAULT_ENG = "eng"
    
    public init(session: URLSession = .shared) {
        self.session = session
    }
    
    public func renderSvg(vcJsonString: String) async -> String {
          do {
              
              guard !vcJsonString.isEmpty else {
                  return ""
              }
            
              if let data = vcJsonString.data(using: .utf8),
                 let jsonObject = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                 let renderMethodArray = jsonObject["renderMethod"] as? [[String: Any]],
                 let firstRenderMethod = renderMethodArray.first,
                 let svgUrl = firstRenderMethod["id"] as? String {
                  
                  let template = try await fetchString(from: svgUrl)
                  
                  let processedJson = PreProcessor().preProcessVcJson(vcJsonString: vcJsonString, svgTemplate: template)
                
                  return replacePlaceholders(svgTemplate: template, processedJson: processedJson)
              }
          } catch {
              print("Error rendering SVG: \(error)")
          }
          
          return ""
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
    

    func replacePlaceholders(svgTemplate: String, processedJson: [String: Any]) -> String {
        let regexPattern = PLACEHOLDER_REGEX_PATTERN

        guard let regex = try? NSRegularExpression(pattern: regexPattern, options: []) else {
            return svgTemplate
        }

        var modifiedTemplate = svgTemplate

        regex.enumerateMatches(in: svgTemplate, options: [], range: NSRange(location: 0, length: svgTemplate.utf16.count)) { match, flags, stop in
            guard let match = match, let keyRange = Range(match.range(at: 1), in: svgTemplate) else { return }
            
            let key = String(svgTemplate[keyRange]).trimmingCharacters(in: .whitespaces)
            let value = self.getValueFromData(key: key, jsonObject: processedJson)
            let valueString = value.map { "\($0)" } ?? ""
            
            modifiedTemplate = modifiedTemplate.replacingOccurrences(of: "{{\(key)}}", with: valueString)
        }
        
        return modifiedTemplate
    }

    private func getValueFromData(key: String, jsonObject: [String: Any], isDefaultLanguageHandle: Bool = false) -> Any? {
        let keys = key.split(separator: "/").map(String.init)
        var currentValue: Any? = jsonObject

        for k in keys {
            if let dict = currentValue as? [String: Any] {
                currentValue = dict[k]
            } else if let array = currentValue as? [Any], let index = Int(k), index < array.count {
                currentValue = array[index]
            } else {
                return nil
            }
        }

        // Setting Default Language to English
        if let dict = currentValue as? [String: Any] {
            return dict[DEFAULT_ENG] ?? nil
        } else if currentValue == nil && keys.count > 0 && !isDefaultLanguageHandle {
            let updatedKey = keys.dropLast().joined(separator: "/") + "/\(DEFAULT_ENG)"
            return getValueFromData(key: updatedKey, jsonObject: jsonObject, isDefaultLanguageHandle: true)
        } else {
            return currentValue
        }
    }
    
    
    
}


