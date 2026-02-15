import SwiftUI
import WebKit

struct MarkdownWebView: NSViewRepresentable {
    let markdown: String

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.setValue(false, forKey: "drawsBackground")

        let html = HTMLTemplate.page(body: MarkdownParser.toHTML(markdown))
        webView.loadHTMLString(html, baseURL: nil)
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        let bodyHTML = MarkdownParser.toHTML(markdown)
        let escaped = bodyHTML
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "`", with: "\\`")
            .replacingOccurrences(of: "${", with: "\\${")

        if context.coordinator.isLoaded {
            webView.evaluateJavaScript("document.body.innerHTML = `\(escaped)`;", completionHandler: nil)
        } else {
            context.coordinator.pendingUpdate = escaped
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        var isLoaded = false
        var pendingUpdate: String?

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            isLoaded = true
            if let update = pendingUpdate {
                webView.evaluateJavaScript("document.body.innerHTML = `\(update)`;", completionHandler: nil)
                pendingUpdate = nil
            }
        }
    }
}
