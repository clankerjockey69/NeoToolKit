import SwiftUI
import CryptoKit
import UniformTypeIdentifiers
import UIKit

@main
struct NeoToolkitApp: App {
    var body: some Scene { WindowGroup { HomeView().tint(.purple) } }
}

struct ResultView: View {
    let text: String
    var body: some View {
        Section("Result") {
            Text(text.isEmpty ? "Your result appears here." : text)
                .font(.system(.body, design: .monospaced)).textSelection(.enabled)
            if !text.isEmpty {
                Button("Copy result", systemImage: "doc.on.doc") {
                    UIPasteboard.general.setItems([[UIPasteboard.typeAutomatic: text]],
                                                 options: [.localOnly: true, .expirationDate: Date().addingTimeInterval(120)])
                }
                ShareLink(item: text)
            }
        }
    }
}

struct HomeView: View {
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Label("NEO TOOLKIT", systemImage: "sparkles").font(.title.bold())
                    Text("Local tools. No activation key. No account.").foregroundStyle(.secondary)
                }
                Section("Your tools") {
                    NavigationLink { PasswordView() } label: { Label("Password generator", systemImage: "key.fill") }
                    NavigationLink { HashView() } label: { Label("File checksum", systemImage: "doc.badge.gearshape") }
                    NavigationLink { TextToolsView() } label: { Label("Text tools", systemImage: "textformat.abc") }
                    NavigationLink { URLInspectorView() } label: { Label("URL inspector", systemImage: "link") }
                }
                Section("About") {
                    Text("Independent app written from scratch. Files and text stay on your device unless you choose to share them. No telemetry or saved history.")
                    Text("Copy uses a local clipboard item that expires after two minutes. These tools do not check whether a website is safe.")
                        .foregroundStyle(.secondary)
                }
            }.navigationTitle("Neo Toolkit")
        }
    }
}

struct PasswordView: View {
    @State private var length = 24
    @State private var result = ""
    var body: some View {
        Form {
            Section("Settings") {
                Stepper("Length: \(length)", value: $length, in: 12...128)
                Button("Generate password") {
                    let groups = [Array("abcdefghijklmnopqrstuvwxyz"), Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ"),
                                  Array("0123456789"), Array("!@#$%^&*()-_=+")]
                    let alphabet = groups.flatMap { $0 }
                    var rng = SystemRandomNumberGenerator()
                    var chars = groups.map { $0.randomElement(using: &rng)! }
                    chars += (0..<(length - 4)).map { _ in alphabet.randomElement(using: &rng)! }
                    chars.shuffle(using: &rng)
                    result = String(chars)
                }
            }
            ResultView(text: result)
        }.navigationTitle("Passwords")
    }
}

enum ToolError: LocalizedError {
    case invalid(String)
    var errorDescription: String? { if case .invalid(let message) = self { return message }; return nil }
}

enum TextMode: String, CaseIterable, Identifiable {
    case encode64 = "Base64 encode", decode64 = "Base64 decode"
    case encodeURL = "URL encode", decodeURL = "URL decode"
    case json = "Format JSON", sha = "SHA-256"
    var id: String { rawValue }
    func convert(_ text: String) throws -> String {
        switch self {
        case .encode64: return Data(text.utf8).base64EncodedString()
        case .decode64:
            guard let data = Data(base64Encoded: text), let value = String(data: data, encoding: .utf8) else {
                throw ToolError.invalid("Enter valid Base64 containing UTF-8 text.")
            }
            return value
        case .encodeURL:
            return text.addingPercentEncoding(withAllowedCharacters: CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~")) ?? ""
        case .decodeURL:
            guard let value = text.removingPercentEncoding else { throw ToolError.invalid("Invalid percent encoding.") }
            return value
        case .json:
            let value = try JSONSerialization.jsonObject(with: Data(text.utf8), options: [.fragmentsAllowed])
            let data = try JSONSerialization.data(withJSONObject: value, options: [.prettyPrinted, .sortedKeys, .fragmentsAllowed])
            return String(decoding: data, as: UTF8.self)
        case .sha: return SHA256.hash(data: Data(text.utf8)).map { String(format: "%02x", $0) }.joined()
        }
    }
}

struct TextToolsView: View {
    @State private var mode: TextMode = .encode64
    @State private var input = ""
    @State private var result = ""
    var body: some View {
        Form {
            Picker("Tool", selection: $mode) { ForEach(TextMode.allCases) { Text($0.rawValue).tag($0) } }
            Section("Input") {
                TextEditor(text: $input).frame(minHeight: 140).autocorrectionDisabled().textInputAutocapitalization(.never)
                Button("Convert") {
                    do { result = try mode.convert(input) } catch { result = error.localizedDescription }
                }
            }
            ResultView(text: result)
        }.navigationTitle("Text tools")
    }
}

struct URLInspectorView: View {
    @State private var input = ""
    @State private var result = ""
    var body: some View {
        Form {
            Section("URL") {
                TextField("https://example.com/path", text: $input).keyboardType(.URL)
                    .textInputAutocapitalization(.never).autocorrectionDisabled()
                Button("Inspect locally") {
                    guard let parts = URLComponents(string: input.trimmingCharacters(in: .whitespacesAndNewlines)),
                          ["http", "https"].contains(parts.scheme?.lowercased() ?? ""),
                          let host = parts.host, !host.isEmpty else {
                        result = "Enter a complete http:// or https:// URL."; return
                    }
                    let query = (parts.queryItems ?? []).map { "\($0.name) = \($0.value ?? "")" }.joined(separator: "\n")
                    result = "Scheme: \(parts.scheme ?? "")\nHost: \(host)\nPort: \(parts.port.map(String.init) ?? "default")\nPath: \(parts.path)\nEmbedded credentials: \(parts.user != nil || parts.password != nil ? "yes" : "no")\n\nQuery parameters:\n\(query)\n\nFragment: \(parts.fragment ?? "")"
                }
                Text("Does not open the website or determine its safety.").font(.footnote).foregroundStyle(.secondary)
            }
            ResultView(text: result)
        }.navigationTitle("URL inspector")
    }
}

struct HashView: View {
    @State private var importing = false
    @State private var busy = false
    @State private var result = ""
    var body: some View {
        Form {
            Section {
                Button("Choose file from Files", systemImage: "folder") { importing = true }.disabled(busy)
                if busy { ProgressView("Calculating SHA-256…") }
                Text("Reads your selected file in chunks. Nothing is uploaded.").font(.footnote).foregroundStyle(.secondary)
            }
            ResultView(text: result)
        }.navigationTitle("File checksum")
        .fileImporter(isPresented: $importing, allowedContentTypes: [.item]) { selection in
            switch selection {
            case .failure(let error): result = error.localizedDescription
            case .success(let url):
                busy = true
                Task {
                    let output = await Task.detached(priority: .userInitiated) { () -> String in
                        let access = url.startAccessingSecurityScopedResource()
                        defer { if access { url.stopAccessingSecurityScopedResource() } }
                        do {
                            let stream = try FileHandle(forReadingFrom: url)
                            defer { try? stream.close() }
                            var hash = SHA256()
                            while let data = try stream.read(upToCount: 1_048_576), !data.isEmpty { hash.update(data: data) }
                            let digest = hash.finalize().map { String(format: "%02x", $0) }.joined()
                            return "\(url.lastPathComponent)\n\nSHA-256\n\(digest)"
                        } catch { return error.localizedDescription }
                    }.value
                    await MainActor.run { result = output; busy = false }
                }
            }
        }
    }
}
