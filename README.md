# Neo Toolkit for iPhone

Native SwiftUI source for iPhone and iPad, iOS 17+. Independent app written from scratch. No app activation key, API key, server, account, or telemetry.

Features: password generator (12–128 characters), file SHA-256 via Files, UTF-8 Base64, URL percent encoding, JSON formatter, text SHA-256, offline URL inspection, copy and share. Clipboard copies expire in two minutes and are local to the device. No saved history. Network ping and DNS tools from the desktop edition are not included.

## Build without a Mac using GitHub Actions

1. Create a GitHub repository.
2. Extract this ZIP. Upload the CONTENTS of the NeoToolkit-iPhone folder into the repository root, including `.github/workflows/build-ios.yml`. Do not upload only the ZIP or add an extra outer folder. If your uploader hides `.github`, manually create the file with that exact path in GitHub.
3. Open Actions > Build iPhone IPA > Run workflow.
4. When successful, open the run and download the NeoToolkit-iPhone-unsigned artifact. Extract its ZIP to get `NeoToolkit-unsigned.ipa`.

The workflow requires no repository secrets or signing keys to compile. GitHub Actions usage and availability depend on your account. It downloads XcodeGen on a macOS runner.

## Install

The workflow produces an UNSIGNED IPA, not an immediately installable app. iOS requires it to be signed through a supported signing/sideloading method or a developer provisioning workflow. The project does not disable iOS signature checks. If you already have a working signing method, sign the IPA with it. Otherwise installation may require a computer or developer setup. There is no Astri app license key.

## Build with Xcode on a Mac

Install Xcode and XcodeGen, run `xcodegen generate` in this folder, open NeoToolkit.xcodeproj, choose your Apple development team under Signing & Capabilities, then run on your connected iPhone. Use a unique bundle identifier if needed.

## Validation status

Source and project configuration were reviewed and YAML parsed. The authoring environment has no Swift compiler, Apple SDK, or iOS simulator, so compilation and device testing are NOT verified. The first GitHub Actions run is the actual build check. No compiled IPA is included in this ZIP.
