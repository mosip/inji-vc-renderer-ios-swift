# inji-vc-renderer-ios-swift
Swift library to render VC with SVG template support. Replaces the placeholders in the SVG Template to generate a valid SVG Image.


## Installation


To include InjiVcRenderer in your Swift project:

- Create a new Swift project.
- Add package dependency: Enter Package URL of InjiVcRenderer repo


#### API

- `renderSvg(from: vcJsonString)` - expects the Verifiable Credential as parameter and returns the replaced SVG Template.
    - `vcJsonData` - VC Downloaded in stringified format.
