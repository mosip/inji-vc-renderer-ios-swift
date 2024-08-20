import Foundation
import pixelpass

public struct InjiVcRenderer {
    
    private let session: URLSession
    private let QRCODE_IMAGE_TYPE = "data:image/png;base64,"
    private let QRCODE_PLACEHOLDER = "{{qrCodeImage}}"

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
            if let base64String = updateQrCode(jsonString) {
                template = template.replacingOccurrences(of: QRCODE_PLACEHOLDER, with: base64String)
            }
            print("Fetched template content: \(template)")
            var result = template
            let regex: NSRegularExpression
            do {
                regex = try NSRegularExpression(pattern: "\\{\\{([^}]+)\\}\\}", options: [])
            } catch {
                print("Invalid regular expression pattern: \(error)")
                return ""
            }
            let matches = regex.matches(in: template, options: [], range: NSRange(location: 0, length: template.utf16.count))
            for match in matches.reversed() {
                if let range = Range(match.range(at: 1), in: template) {
                    let key = String(template[range])
                    let components = key.split(separator: "/").map(String.init)
                    var value: Any? = values
                    for component in components {
                        value = (value as? [String: Any])?[component]
                    }
                    if let value = value as? String {
                        result = result.replacingOccurrences(of: "{{\(key)}}", with: value)
                    }
                }
            }
            return result
        } catch {
            print("Failed to fetch content: \(error)")
            return ""
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
    
    private func updateQrCode(_ vcJson: String) -> String? {
        let pixelPass = PixelPass()
        if let qrCodeData = pixelPass.generateQRCode(data: vcJson,  ecc: .M, header: "HDR") {
            let base64String = QRCODE_IMAGE_TYPE+qrCodeData.base64EncodedString()
            return base64String
        }
        return nil
    }
}
