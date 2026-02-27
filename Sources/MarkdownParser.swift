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
            let placeholder = "%%CODEBLOCK\(i)%%"
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
            let placeholder = "%%INLINECODE\(i)%%"
            inlineCode[placeholder] = "<code>\(escapeHTML(String(code)))</code>"
            text.replaceSubrange(Range(match.range, in: text)!, with: placeholder)
        }

        // Extract display math ($$...$$) — protect from markdown processing
        var displayMath: [String: String] = [:]
        let displayMathPattern = try! NSRegularExpression(pattern: "\\$\\$([\\s\\S]*?)\\$\\$", options: [])
        let displayMathMatches = displayMathPattern.matches(in: text, range: NSRange(text.startIndex..., in: text))
        for (i, match) in displayMathMatches.reversed().enumerated() {
            let content = text[Range(match.range(at: 1), in: text)!]
            let placeholder = "%%DISPLAYMATH\(i)%%"
            displayMath[placeholder] = "$$\(content)$$"
            text.replaceSubrange(Range(match.range, in: text)!, with: placeholder)
        }

        // Extract inline math ($...$) — protect from markdown processing
        var inlineMath: [String: String] = [:]
        let inlineMathPattern = try! NSRegularExpression(pattern: "(?<!\\$)\\$(?!\\$)([^$\\n]+)\\$(?!\\$)", options: [])
        let inlineMathMatches = inlineMathPattern.matches(in: text, range: NSRange(text.startIndex..., in: text))
        for (i, match) in inlineMathMatches.reversed().enumerated() {
            let content = text[Range(match.range(at: 1), in: text)!]
            let placeholder = "%%INLINEMATH\(i)%%"
            inlineMath[placeholder] = "$\(content)$"
            text.replaceSubrange(Range(match.range, in: text)!, with: placeholder)
        }

        // Extract footnote definitions
        var footnotes: [(id: String, text: String)] = []
        var footnoteMap: [String: Int] = [:]
        let footnoteDefPattern = try! NSRegularExpression(pattern: "^\\[\\^([^\\]]+)\\]:\\s*(.+)$", options: .anchorsMatchLines)
        let footnoteDefMatches = footnoteDefPattern.matches(in: text, range: NSRange(text.startIndex..., in: text))
        for match in footnoteDefMatches.reversed() {
            let id = String(text[Range(match.range(at: 1), in: text)!])
            let body = String(text[Range(match.range(at: 2), in: text)!])
            footnotes.insert((id: id, text: body), at: 0)
            text.replaceSubrange(Range(match.range, in: text)!, with: "")
        }
        for (index, fn) in footnotes.enumerated() {
            footnoteMap[fn.id] = index + 1
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
                let slug = slugify(content)
                html.append("<h\(level) id=\"\(slug)\">\(inlineFormat(content))</h\(level)>")
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

            // Table
            if line.contains("|"), i + 1 < lines.count,
               lines[i + 1].range(of: "^\\|?[\\s:]*-{3,}[\\s:]*(?:\\|[\\s:]*-{3,}[\\s:]*)+\\|?$", options: .regularExpression) != nil {
                closeBlockquote(&html, &inBlockquote)
                let headerCells = parsePipeLine(line)
                let separatorCells = parsePipeLine(lines[i + 1])
                var alignments: [String] = []
                for cell in separatorCells {
                    let trimmed = cell.trimmingCharacters(in: .whitespaces)
                    if trimmed.hasPrefix(":") && trimmed.hasSuffix(":") {
                        alignments.append("center")
                    } else if trimmed.hasSuffix(":") {
                        alignments.append("right")
                    } else {
                        alignments.append("left")
                    }
                }
                html.append("<table>")
                html.append("<thead><tr>")
                for (col, cell) in headerCells.enumerated() {
                    let align = col < alignments.count ? alignments[col] : "left"
                    html.append("<th style=\"text-align:\(align)\">\(inlineFormat(cell.trimmingCharacters(in: .whitespaces)))</th>")
                }
                html.append("</tr></thead>")
                html.append("<tbody>")
                i += 2
                while i < lines.count, lines[i].contains("|") {
                    let bodyCells = parsePipeLine(lines[i])
                    html.append("<tr>")
                    for (col, cell) in bodyCells.enumerated() {
                        let align = col < alignments.count ? alignments[col] : "left"
                        html.append("<td style=\"text-align:\(align)\">\(inlineFormat(cell.trimmingCharacters(in: .whitespaces)))</td>")
                    }
                    html.append("</tr>")
                    i += 1
                }
                html.append("</tbody></table>")
                continue
            }

            // Empty line
            if line.trimmingCharacters(in: .whitespaces).isEmpty {
                i += 1
                continue
            }

            // Code block placeholder
            if line.hasPrefix("%%CODEBLOCK") {
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

        // Replace footnote references
        for (id, number) in footnoteMap {
            result = result.replacingOccurrences(
                of: "[^\(id)]",
                with: "<sup><a href=\"#fn-\(number)\">\(number)</a></sup>"
            )
        }

        // Restore math, code blocks, and inline code
        for (placeholder, replacement) in inlineMath {
            result = result.replacingOccurrences(of: placeholder, with: replacement)
        }
        for (placeholder, replacement) in displayMath {
            result = result.replacingOccurrences(of: placeholder, with: replacement)
        }
        for (placeholder, replacement) in codeBlocks {
            result = result.replacingOccurrences(of: placeholder, with: replacement)
        }
        for (placeholder, replacement) in inlineCode {
            result = result.replacingOccurrences(of: placeholder, with: replacement)
        }

        // Append footnotes section
        if !footnotes.isEmpty {
            result += "\n<section class=\"footnotes\"><hr><ol>"
            for (index, fn) in footnotes.enumerated() {
                let num = index + 1
                result += "<li id=\"fn-\(num)\">\(inlineFormat(fn.text)) <a href=\"#fn-\(num)\">\u{21A9}</a></li>"
            }
            result += "</ol></section>"
        }

        return result
    }

    private static func parsePipeLine(_ line: String) -> [String] {
        var stripped = line
        if stripped.hasPrefix("|") { stripped = String(stripped.dropFirst()) }
        if stripped.hasSuffix("|") { stripped = String(stripped.dropLast()) }
        return stripped.components(separatedBy: "|")
    }

    private static func inlineFormat(_ text: String) -> String {
        var result = text

        // Extract images and links FIRST to protect URLs from smart typography
        var linkPlaceholders: [String: String] = [:]
        var counter = 0

        let imgPattern = try! NSRegularExpression(pattern: "!\\[([^\\]]*)\\]\\(([^)]+)\\)")
        for m in imgPattern.matches(in: result, range: NSRange(result.startIndex..., in: result)).reversed() {
            let alt = String(result[Range(m.range(at: 1), in: result)!])
            let src = String(result[Range(m.range(at: 2), in: result)!])
            let ph = "%%ILINK\(counter)%%"
            counter += 1
            linkPlaceholders[ph] = "<img src=\"\(src)\" alt=\"\(alt)\">"
            result.replaceSubrange(Range(m.range, in: result)!, with: ph)
        }

        let linkPattern = try! NSRegularExpression(pattern: "\\[([^\\]]+)\\]\\(([^)]+)\\)")
        for m in linkPattern.matches(in: result, range: NSRange(result.startIndex..., in: result)).reversed() {
            let linkText = String(result[Range(m.range(at: 1), in: result)!])
            let url = String(result[Range(m.range(at: 2), in: result)!])
            let ph = "%%ILINK\(counter)%%"
            counter += 1
            linkPlaceholders[ph] = "<a href=\"\(url)\">\(linkText)</a>"
            result.replaceSubrange(Range(m.range, in: result)!, with: ph)
        }

        // Smart typography (safe now — code/math/links all extracted)
        result = result.replacingOccurrences(of: "---", with: "\u{2014}")  // em-dash
        result = result.replacingOccurrences(of: "--", with: "\u{2013}")   // en-dash
        result = result.replacingOccurrences(of: "...", with: "\u{2026}") // ellipsis
        result = result.replacingOccurrences(
            of: "\"([^\"]+)\"",
            with: "\u{201C}$1\u{201D}",
            options: .regularExpression
        )
        result = result.replacingOccurrences(
            of: "'([^']+)'",
            with: "\u{2018}$1\u{2019}",
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

        // Restore links and images
        for (ph, replacement) in linkPlaceholders {
            result = result.replacingOccurrences(of: ph, with: replacement)
        }

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

    private static func slugify(_ text: String) -> String {
        // Strip placeholder tokens and markdown formatting before slugifying
        var s = text
        s = s.replacingOccurrences(of: "%%[A-Z]+\\d+%%", with: "", options: .regularExpression)
        s = s.replacingOccurrences(of: "[*_`~\\[\\]]", with: "", options: .regularExpression)
        return s.lowercased()
            .replacingOccurrences(of: "[^a-z0-9\\s-]", with: "", options: .regularExpression)
            .replacingOccurrences(of: "\\s", with: "-", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
    }

    private static func closeBlockquote(_ html: inout [String], _ inBlockquote: inout Bool) {
        if inBlockquote {
            html.append("</blockquote>")
            inBlockquote = false
        }
    }
}
