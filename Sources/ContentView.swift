import SwiftUI

enum ViewMode: String, CaseIterable {
    case view = "View"
    case edit = "Edit"
}

struct ContentView: View {
    @Binding var document: MarkdownDocument
    @State private var mode: ViewMode = .view

    var body: some View {
        VStack(spacing: 0) {
            Picker("Mode", selection: $mode) {
                ForEach(ViewMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .padding(8)
            .frame(maxWidth: 200)

            Divider()

            switch mode {
            case .view:
                MarkdownWebView(markdown: document.text)
            case .edit:
                TextEditor(text: $document.text)
                    .font(.system(.body, design: .monospaced))
                    .padding(4)
            }
        }
        .frame(minWidth: 600, minHeight: 400)
    }
}
