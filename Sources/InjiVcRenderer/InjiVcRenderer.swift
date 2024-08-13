import Foundation

public struct InjiVcRenderer {
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func renderSvg(from jsonString: String) async -> String {
        print("renderSvg")
        
        guard let values = jsonStringToDictionary(jsonString),
              let templateURL = extractTemplateURL(from: values) else {
            return ""
        }
        print("values:\n\(values)")
        
      
        do {
                      let templateURL = "https://5825-2401-4900-1cd1-2813-4f0-c58f-b836-395d.ngrok-free.app/insurance_svg_template.svg" // Replace with your actual URL
                      let template = try await fetchString(from: templateURL)
                      print("Content:\n\(template)")
                      // Assign result to a variable and use it as needed
                      // For example:
                      // self.processFetchedContent(content)
            var result = template
             
             // Regular expression to find placeholders
             let regex = try! NSRegularExpression(pattern: "\\{\\{([^}]+)\\}\\}", options: [])
             let matches = regex.matches(in: template, options: [], range: NSRange(location: 0, length: template.utf16.count))
             
             for match in matches.reversed() {
                 if let range = Range(match.range(at: 1), in: template) {
                     let key = String(template[range])
                     
                     // Split key into path components
                     let components = key.split(separator: "/").map(String.init)
                     
                     // Extract value from dictionary
                     var value: Any? = values
                     for component in components {
                         value = (value as? [String: Any])?[component]
                     }
                     
                     // Format the date if it's in a recognized format
                     if let dateString = value as? String, let formattedDate = self.formatDateString(dateString) {
                         value = formattedDate
                     }
                     
                     // Replace placeholder with value
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
    func fetchString(from urlString: String) async throws -> String {
        guard let url = URL(string: urlString) else {
            throw NSError(domain: "Invalid URL", code: 0, userInfo: nil)
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "Invalid response", code: 0, userInfo: nil)
        }

        guard let string = String(data: data, encoding: .utf8) else {
            throw NSError(domain: "Failed to convert data to string", code: 0, userInfo: nil)
        }

        return string
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

    public func formatDateString(_ dateString: String) -> String? {
        let dateFormats = [
            "yyyy-MM-dd'T'HH:mm:ss.SSSZ", // ISO 8601 with milliseconds
            "yyyy-MM-dd'T'HH:mm:ssZ", // ISO 8601 with timezone
            "yyyy-MM-dd'T'HH:mm:ss", // ISO 8601 without timezone
            "yyyy-MM-dd" // Basic date format
        ]

        for format in dateFormats {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = format
            dateFormatter.timeZone = TimeZone(abbreviation: "UTC") // Handle UTC timezone
            if let date = dateFormatter.date(from: dateString) {
                let outputFormatter = DateFormatter()
                outputFormatter.dateFormat = "yyyy/MM/dd"
                return outputFormatter.string(from: date)
            }
        }

        // Return nil if no valid date format is found
        return nil
    }
}
