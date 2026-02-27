import Foundation

enum HTMLTemplate {
    static func page(body: String) -> String {
        """
        <!DOCTYPE html>
        <html>
        <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/katex@0.16.11/dist/katex.min.css">
        <script defer src="https://cdn.jsdelivr.net/npm/katex@0.16.11/dist/katex.min.js"></script>
        <script defer src="https://cdn.jsdelivr.net/npm/katex@0.16.11/dist/contrib/auto-render.min.js"></script>
        <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/prismjs@1.29.0/themes/prism.min.css" media="(prefers-color-scheme: light)">
        <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/prismjs@1.29.0/themes/prism-tomorrow.min.css" media="(prefers-color-scheme: dark)">
        <script defer src="https://cdn.jsdelivr.net/npm/prismjs@1.29.0/prism.min.js"></script>
        <script defer src="https://cdn.jsdelivr.net/npm/prismjs@1.29.0/plugins/autoloader/prism-autoloader.min.js"></script>
        <style>
        @import url('https://cdn.jsdelivr.net/gh/aaaakshat/cm-web-fonts@latest/fonts.css');

        :root {
            --bg: #ffffff;
            --fg: #1a1a1a;
            --fg-secondary: #444444;
            --code-bg: #f5f5f0;
            --border: #cccccc;
            --link: #0645ad;
            --blockquote-border: #999999;
        }

        @media (prefers-color-scheme: dark) {
            :root {
                --bg: #1a1a1a;
                --fg: #e0e0e0;
                --fg-secondary: #aaaaaa;
                --code-bg: #2a2a2a;
                --border: #555555;
                --link: #6ca0dc;
                --blockquote-border: #666666;
            }
        }

        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: "Computer Modern Serif", Georgia, "Times New Roman", serif;
            font-size: 12pt;
            line-height: 1.6;
            color: var(--fg);
            background-color: var(--bg);
            max-width: 700px;
            margin: 0 auto;
            padding: 40px 20px;
            text-align: justify;
            hyphens: auto;
            -webkit-hyphens: auto;
        }

        h1, h2, h3, h4, h5, h6 {
            font-weight: normal;
            text-align: left;
            margin-top: 1.5em;
            margin-bottom: 0.5em;
            line-height: 1.3;
        }

        h1 {
            font-size: 2em;
            text-align: center;
            margin-top: 0.5em;
            margin-bottom: 1em;
        }

        h2 { font-size: 1.5em; }
        h3 { font-size: 1.25em; font-style: italic; }
        h4 { font-size: 1.1em; font-style: italic; }
        h5 { font-size: 1em; }
        h6 { font-size: 0.9em; color: var(--fg-secondary); }

        p {
            margin-bottom: 1em;
            text-indent: 0;
        }

        a {
            color: var(--link);
            text-decoration: none;
        }

        a:hover { text-decoration: underline; }

        strong { font-weight: bold; }
        em { font-style: italic; }

        code {
            font-family: "Computer Modern Typewriter", "Courier New", monospace;
            font-size: 0.9em;
            background-color: var(--code-bg);
            padding: 2px 5px;
            border-radius: 3px;
        }

        pre {
            background-color: var(--code-bg);
            padding: 16px;
            border-radius: 4px;
            overflow-x: auto;
            margin-bottom: 1em;
            border: 1px solid var(--border);
        }

        pre code {
            background: none;
            padding: 0;
            font-size: 0.85em;
            line-height: 1.5;
        }

        blockquote {
            border-left: 3px solid var(--blockquote-border);
            padding-left: 1em;
            margin-left: 0;
            margin-bottom: 1em;
            color: var(--fg-secondary);
            font-style: italic;
        }

        ul, ol {
            margin-bottom: 1em;
            padding-left: 2em;
        }

        li { margin-bottom: 0.3em; }

        hr {
            border: none;
            border-top: 1px solid var(--border);
            margin: 2em 0;
        }

        img {
            max-width: 100%;
            height: auto;
            display: block;
            margin: 1em auto;
        }

        table {
            border-collapse: collapse;
            width: 100%;
            margin-bottom: 1em;
            border-top: 2px solid var(--fg);
            border-bottom: 2px solid var(--fg);
        }

        th, td {
            padding: 6px 12px;
            border: none;
        }

        thead tr {
            border-bottom: 1px solid var(--fg);
        }

        th { font-weight: bold; }

        pre[class*="language-"],
        code[class*="language-"] {
            background-color: var(--code-bg) !important;
        }

        .footnotes {
            margin-top: 2em;
            font-size: 0.85em;
            color: var(--fg-secondary);
        }

        .footnotes hr {
            border: none;
            border-top: 1px solid var(--border);
            margin-bottom: 0.5em;
        }

        .footnotes ol {
            padding-left: 1.5em;
        }

        .katex-display {
            margin: 1em 0;
            text-align: center;
        }
        </style>
        <script>
        function renderMath() {
            if (typeof renderMathInElement === 'function') {
                renderMathInElement(document.body, {
                    delimiters: [
                        {left: '$$', right: '$$', display: true},
                        {left: '$', right: '$', display: false}
                    ],
                    throwOnError: false
                });
            }
        }
        function renderAll() {
            renderMath();
            if (typeof Prism !== 'undefined') { Prism.highlightAll(); }
        }
        document.addEventListener('DOMContentLoaded', function() {
            var check = setInterval(function() {
                if (typeof renderMathInElement === 'function') {
                    clearInterval(check);
                    renderAll();
                }
            }, 50);
        });
        // Handle anchor links in WKWebView (fragment navigation doesn't work with loadHTMLString)
        document.addEventListener('click', function(e) {
            var a = e.target.closest('a[href^="#"]');
            if (a) {
                e.preventDefault();
                var id = a.getAttribute('href').substring(1);
                var target = document.getElementById(id);
                // Fallback: find first element whose id starts with the anchor
                if (!target) {
                    var els = document.querySelectorAll('[id]');
                    for (var i = 0; i < els.length; i++) {
                        if (els[i].id.indexOf(id) === 0) { target = els[i]; break; }
                    }
                }
                if (target) {
                    target.scrollIntoView({ behavior: 'smooth' });
                }
            }
        });
        </script>
        </head>
        <body>
        \(body)
        </body>
        </html>
        """
    }
}
