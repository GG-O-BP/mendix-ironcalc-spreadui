# Security policy

## Reporting

Please report a suspected vulnerability through GitHub's private vulnerability
reporting for this repository. Do not include real Mendix credentials,
production workbook contents, or customer data in an issue.

## Data boundary

The widget performs spreadsheet calculation in the browser. It does not send
Mendix datasource values or persisted workbook bytes to an external service.
Workbook downloads are initiated locally by the browser.

## Dependency audit note (August 31, 2026)

`bun audit` reports the upstream `image-size` ICNS/JXL/HEIF denial-of-service
advisories through Metro and React Native. That chain is installed by the
Mendix widget development/test tooling and is not imported into the production
SpreadUI bundle. No fixed `image-size` release is currently available in the
npm registry; update the lockfile when its upstream fix is published.
