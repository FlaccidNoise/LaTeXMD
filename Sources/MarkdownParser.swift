import Foundation

enum MarkdownParser {
    static func toHTML(_ markdown: String) -> String {
        var text = markdown

        // Extract code blocks first to prevent parsing markdown inside them
        var codeBlocks: [String: String] = [:]
        let codeBlockPattern = try! NSRegularExpression(pattern: "```(\\w*)\\n([\\s\\S]*?)```", options: [])
        let codeMatches = codeBlockPattern.matches(in: text, range: NSRange(text.startIndex..., in: text))
        for (i, match) in codeMatches.reversed().enumerated() {
            let lang = text[Range(match.range(at: 1), in: text)!]
            let code = text[Range(match.range(at: 2), in: text)!]
            let placeholder = "%%CODEBLOCK_\(i)%%"
            let escaped = escapeHTML(String(code))
            let langAttr = lang.isEmpty ? "" : " class=\"language-\(lang)\""
            codeBlocks[placeholder] = "<pre><code\(langAttr)>\(escaped)</code></pre>"
            text.replaceSubrange(Range(match.range, in: text)!, with: placeholder)
        }

        // Extract inline code
        var inlineCode: [String: String] = [:]
        let inlineCodePattern = try! NSRegularExpression(pattern: "`([^`]+)`", options: [])
        let inlineMatches = inlineCodePattern.matches(in: text, range: NSRange(text.startIndex..., in: text))
        for (i, match) in inlineMatches.reversed().enumerated() {
            let code = text[Range(match.range(at: 1), in: text)!]
            let placeholder = "%%INLINECODE_\(i)%%"
            inlineCode[placeholder] = "<code>\(escapeHTML(String(code)))</code>"
            text.replaceSubrange(Range(match.range, in: text)!, with: placeholder)
        }

        // Process line by line
        let lines = text.components(separatedBy: "\n")
        var html: [String] = []
        var inList = false
        var listType = ""
        var inBlockquote = false

        var i = 0
        while i < lines.count {
            let line = lines[i]

            // Horizontal rule
            if line.range(of: "^\\s*([-*_]\\s*){3,}$", options: .regularExpression) != nil {
                closeList(&html, &inList, &listType)
                closeBlockquote(&html, &inBlockquote)
                html.append("<hr>")
                i += 1
                continue
            }

            // Headers
            if let headerMatch = line.range(of: "^(#{1,6})\\s+(.+)$", options: .regularExpression) {
                closeList(&html, &inList, &listType)
                closeBlockquote(&html, &inBlockquote)
                let headerLine = String(line[headerMatch])
                let level = headerLine.prefix(while: { $0 == "#" }).count
                let content = String(headerLine.drop(while: { $0 == "#" }).dropFirst())
                html.append("<h\(level)>\(inlineFormat(content))</h\(level)>")
                i += 1
                continue
            }

            // Blockquote
            if line.hasPrefix("> ") || line == ">" {
                closeList(&html, &inList, &listType)
                if !inBlockquote {
                    html.append("<blockquote>")
                    inBlockquote = true
                }
                let content = line.hasPrefix("> ") ? String(line.dropFirst(2)) : ""
                if !content.isEmpty {
                    html.append("<p>\(inlineFormat(content))</p>")
                }
                i += 1
                continue
            } else {
                closeBlockquote(&html, &inBlockquote)
            }

            // Unordered list
            if line.range(of: "^\\s*[-*+]\\s+", options: .regularExpression) != nil {
                if !inList || listType != "ul" {
                    closeList(&html, &inList, &listType)
                    html.append("<ul>")
                    inList = true
                    listType = "ul"
                }
                let content = line.replacingOccurrences(of: "^\\s*[-*+]\\s+", with: "", options: .regularExpression)
                html.append("<li>\(inlineFormat(content))</li>")
                i += 1
                continue
            }

            // Ordered list
            if line.range(of: "^\\s*\\d+\\.\\s+", options: .regularExpression) != nil {
                if !inList || listType != "ol" {
                    closeList(&html, &inList, &listType)
                    html.append("<ol>")
                    inList = true
                    listType = "ol"
                }
                let content = line.replacingOccurrences(of: "^\\s*\\d+\\.\\s+", with: "", options: .regularExpression)
                html.append("<li>\(inlineFormat(content))</li>")
                i += 1
                continue
            }

            closeList(&html, &inList, &listType)

            // Empty line
            if line.trimmingCharacters(in: .whitespaces).isEmpty {
                i += 1
                continue
            }

            // Code block placeholder
            if line.hasPrefix("%%CODEBLOCK_") {
                html.append(line)
                i += 1
                continue
            }

            // Paragraph
            html.append("<p>\(inlineFormat(line))</p>")
            i += 1
        }

        closeList(&html, &inList, &listType)
        closeBlockquote(&html, &inBlockquote)

        var result = html.joined(separator: "\n")

        // Restore code blocks and inline code
        for (placeholder, replacement) in codeBlocks {
            result = result.replacingOccurrences(of: placeholder, with: replacement)
        }
        for (placeholder, replacement) in inlineCode {
            result = result.replacingOccurrences(of: placeholder, with: replacement)
        }

        return result
    }

    private static func inlineFormat(_ text: String) -> String {
        var result = text

        // Images (before links)
        result = result.replacingOccurrences(
            of: "!\\[([^\\]]*)\\]\\(([^)]+)\\)",
            with: "<img src=\"$2\" alt=\"$1\">",
            options: .regularExpression
        )

        // Links
        result = result.replacingOccurrences(
            of: "\\[([^\\]]+)\\]\\(([^)]+)\\)",
            with: "<a href=\"$2\">$1</a>",
            options: .regularExpression
        )

        // Bold (** or __)
        result = result.replacingOccurrences(
            of: "(\\*\\*|__)(.+?)\\1",
            with: "<strong>$2</strong>",
            options: .regularExpression
        )

        // Italic (* or _) — avoid matching ** or __
        result = result.replacingOccurrences(
            of: "(?<![*_])([*_])(?![*_])(.+?)(?<![*_])\\1(?![*_])",
            with: "<em>$2</em>",
            options: .regularExpression
        )

        return result
    }

    private static func escapeHTML(_ text: String) -> String {
        text.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }

    private static func closeList(_ html: inout [String], _ inList: inout Bool, _ listType: inout String) {
        if inList {
            html.append("</\(listType)>")
            inList = false
            listType = ""
        }
    }

    private static func closeBlockquote(_ html: inout [String], _ inBlockquote: inout Bool) {
        if inBlockquote {
            html.append("</blockquote>")
            inBlockquote = false
        }
    }
}
