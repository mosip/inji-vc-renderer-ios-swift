# inji-vc-renderer-ios-swift
Swift library to render VC with SVG template support. Replaces the placeholders in the SVG Template to generate a valid SVG Image.


## Installation


To include InjiVcRenderer in your Swift project:

- Create a new Swift project.
- Add package dependency: Enter Package URL of InjiVcRenderer repo


#### API

- `renderSvg(vcJsonData: String)` - expects the Verifiable Credential as parameter and returns the replaced SVG Template.
    - `vcJsonData` - VC Downloaded in stringified format.
    - This method takes entire VC data as input.
    
- **Fetch SVG Template**
    - Extracts the svg template url from the render method
    - Downloads the SVG XML string.

- **Replace QR Code**
    - Generates the QR code using Pixelpass library and replaces the `qrCodeImage` placeholder

- **Replace Benefits**
    - Replace the benefits value placeholder with comma separated elements of Benefits array,
    - Example:
  ```
  let vc = """
      {
      "credentialSubject": {
          "benefits": ["Medical Benefit", "Full Checkup", "Critical Inujury"]
      }
  }
  """
  let svgTemplate = "<svg>Policy Benefits : {{benefits1}}{{benefits2}}</svg>"

  const val = replaceBenefits(vc, svgTemplate)
  //result => <svg>Policy Benefits : Medical Benefit,Full Checkup,Critical Inujury</svg>
  
  ```
    - We are splitting the whole comma separate benefits string into two lines through code to accommodate in the svg template design and replacing two placeholders {{benefits1}} and {{benefits2}}.
- **Replace Address**
    - Check for the address fields and create comma separated full Address String.
    - Replace the fullAddress value placeholder with separated elements of full Address String
    - Example:
  ```
  let vc = """
      {
      "credentialSubject": {
          "addressLine1": [{"value": "No 123, Test Address line1"}],
          "addressLine2": [{"value": "Test Address line"}],
          "city": [{"value": "TestCITY"}],
          "province": [{"value": "TESTProvince"}],
      }
  }
  """
  let svgTemplate = "<svg>Full Address : {{fullAddress1}}{{fullAddress2}}</svg>"

  let result = replaceAddress(vc, svgTemplate)
  //result => "<svg>Full Address : No 123, Test Address line1,Test Address line,TestCITY,TESTProvince</svg>"
  
  ```
    - We are splitting the whole comma separate full Address string into two lines through code to accommodate in the svg template design and replacing two placeholders {{fullAddress1}} and {{fullAddress1}}.
- **Replacing other placeholders with VC Data**
    - Example
  ```
          let vc = """
      {
      "credentialSubject": {
          "email": "test@gmail.com",
      }
  }
  """
  let svgTemplate = "<svg>Email : {{credentialSubject/email}}</svg>"
  ```
- Returns the Replaced svg template to render proper SVG Image.
