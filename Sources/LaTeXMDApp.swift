import SwiftUI
import AppKit
import CoreServices

@main
struct LaTeXMDApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        DocumentGroup(newDocument: MarkdownDocument()) { file in
            ContentView(document: file.$document)
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        promptSetDefault()
    }

    private func promptSetDefault() {
        let key = "hasPromptedDefaultApp"
        guard !UserDefaults.standard.bool(forKey: key) else { return }
        UserDefaults.standard.set(true, forKey: key)

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let alert = NSAlert()
            alert.messageText = "Set LaTeXMD as your default Markdown viewer?"
            alert.informativeText = "You can always change this later in Finder via Get Info > Open With."
            alert.addButton(withTitle: "Set as Default")
            alert.addButton(withTitle: "Not Now")
            alert.alertStyle = .informational

            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                self.setAsDefault()
            }
        }
    }

    private func setAsDefault() {
        let bundleID = Bundle.main.bundleIdentifier ?? "com.latexmd.app"
        let mdUTI = "net.daringfireball.markdown" as CFString
        LSSetDefaultRoleHandlerForContentType(mdUTI, .all, bundleID as CFString)
    }
}
