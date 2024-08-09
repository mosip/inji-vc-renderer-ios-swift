import Foundation

public struct InjiVcRenderer {
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func replacePlaceholders(from jsonString: String, completion: @escaping (String?) -> Void) {
        guard let values = jsonStringToDictionary(jsonString),
              let templateURL = extractTemplateURL(from: values) else {
            completion(nil)
            return
        }
        
        fetchTemplate(from: templateURL) { fetchedTemplate in
            guard let template = fetchedTemplate else {
                completion(nil)
                return
            }
            
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
            
            completion(result)
        }
    }

    private func fetchTemplate(from url: URL, completion: @escaping (String?) -> Void) {
        let task = session.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error fetching template: \(error)")
                completion(nil)
                return
            }
            
            guard let data = data, let template = String(data: data, encoding: .utf8) else {
                print("Failed to decode template data")
                completion(nil)
                return
            }
            
            completion(template)
        }
        
        task.resume()
    }

    private func extractTemplateURL(from values: [String: Any]) -> URL? {
        guard let renderMethodArray = values["renderMethod"] as? [[String: Any]],
              let firstRenderMethod = renderMethodArray.first,
              let urlString = firstRenderMethod["id"] as? String,
              let url = URL(string: urlString) else {
            return nil
        }
        
        return url
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
