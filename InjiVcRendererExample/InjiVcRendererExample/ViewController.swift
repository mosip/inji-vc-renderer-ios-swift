import UIKit
import InjiVcRenderer

class ViewController: UIViewController {
    private var renderedSvg: String = ""
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        let renderer = InjiVcRenderer()
        
        
        
        let vcJsonString = """
        {
            "credentialSubject": {
                "policyName": "Policy Name",
                "policyNumber": "123456",
                "fullName": "John Doe",
                "gender": "Male",
                "email": "john.doe@example.com",
                "mobile": "1234567890",
                "policyIssuedOn": "2024-07-01",
                "policyExpiresOn": "2024-12-31"
            },
            "issuanceDate": "2024-05-09T09:10:05.450Z",
            "expirationDate": "2024-12-31T23:59:59.999Z",
             "renderMethod": [{
                  "id": "https://<host-url>/insurance_svg_template.svg",
                  "type": "SvgRenderingTemplate",
                  "name": "Portrait Mode",
                  "css3MediaQuery": "@media (orientation: portrait)",
                  "digestMultibase": "zQmAPdhyxzznFCwYxAp2dRerWC85Wg6wFl9G270iEu5h6JqW"
                }]
        }
        """
        
        Task {
            let svg = await renderer.renderSvg(from: vcJsonString)
            print("Rendered SVG: \(svg)")
        }
    }
    
}
