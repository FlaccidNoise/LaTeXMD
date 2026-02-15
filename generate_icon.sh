#!/bin/bash
# Generate a LaTeX-themed app icon using sips and iconutil

set -e

ICONSET="Assets/AppIcon.iconset"
mkdir -p "$ICONSET"

# Create a 1024x1024 base icon using Python (available on macOS)
python3 -c "
import subprocess, os, tempfile

# Create SVG
svg = '''<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"1024\" height=\"1024\" viewBox=\"0 0 1024 1024\">
  <defs>
    <linearGradient id=\"bg\" x1=\"0%\" y1=\"0%\" x2=\"100%\" y2=\"100%\">
      <stop offset=\"0%\" style=\"stop-color:#2c3e50\"/>
      <stop offset=\"100%\" style=\"stop-color:#1a252f\"/>
    </linearGradient>
  </defs>
  <rect width=\"1024\" height=\"1024\" rx=\"180\" fill=\"url(#bg)\"/>
  <text x=\"512\" y=\"580\" text-anchor=\"middle\" font-family=\"Georgia, serif\"
        font-size=\"520\" fill=\"#ecf0f1\" font-style=\"italic\">M</text>
  <text x=\"512\" y=\"820\" text-anchor=\"middle\" font-family=\"Georgia, serif\"
        font-size=\"140\" fill=\"#95a5a6\" letter-spacing=\"8\">LaTeX</text>
</svg>'''

# Write SVG to temp file
svg_path = os.path.join(tempfile.gettempdir(), 'latexmd_icon.svg')
with open(svg_path, 'w') as f:
    f.write(svg)

# Try to convert using qlmanage (built-in macOS)
png_path = os.path.join(tempfile.gettempdir(), 'latexmd_icon.png')
try:
    subprocess.run(['qlmanage', '-t', '-s', '1024', '-o', tempfile.gettempdir(), svg_path],
                   capture_output=True, timeout=10)
    ql_output = svg_path + '.png'
    if os.path.exists(ql_output):
        os.rename(ql_output, png_path)
    else:
        raise FileNotFoundError('qlmanage output not found')
except Exception:
    # Fallback: create a simple colored PNG with sips
    # Create a minimal valid PNG (solid color) using pure Python
    import struct, zlib

    def create_png(width, height, r, g, b):
        def chunk(chunk_type, data):
            c = chunk_type + data
            return struct.pack('>I', len(data)) + c + struct.pack('>I', zlib.crc32(c) & 0xffffffff)

        header = b'\\x89PNG\\r\\n\\x1a\\n'
        ihdr = chunk(b'IHDR', struct.pack('>IIBBBBB', width, height, 8, 2, 0, 0, 0))

        raw = b''
        for y in range(height):
            raw += b'\\x00'  # filter byte
            for x in range(width):
                # Simple gradient background
                raw += bytes([r, g, b])

        idat = chunk(b'IDAT', zlib.compress(raw))
        iend = chunk(b'IEND', b'')

        return header + ihdr + idat + iend

    png_data = create_png(1024, 1024, 44, 62, 80)
    with open(png_path, 'wb') as f:
        f.write(png_data)

print(png_path)
" > /tmp/icon_base_path.txt

BASE_PNG=$(cat /tmp/icon_base_path.txt)

if [ ! -f "$BASE_PNG" ]; then
    echo "⚠️  Could not generate icon image, creating placeholder"
    # Create a minimal 1x1 PNG and scale it
    python3 -c "
import struct, zlib
def create_png(w, h, r, g, b):
    def chunk(t, d):
        c = t + d
        return struct.pack('>I', len(d)) + c + struct.pack('>I', zlib.crc32(c) & 0xffffffff)
    header = b'\x89PNG\r\n\x1a\n'
    ihdr = chunk(b'IHDR', struct.pack('>IIBBBBB', w, h, 8, 2, 0, 0, 0))
    raw = b''
    for y in range(h):
        raw += b'\x00'
        for x in range(w):
            raw += bytes([r, g, b])
    idat = chunk(b'IDAT', zlib.compress(raw))
    iend = chunk(b'IEND', b'')
    return header + ihdr + idat + iend
with open('/tmp/latexmd_icon.png', 'wb') as f:
    f.write(create_png(16, 16, 44, 62, 80))
"
    BASE_PNG="/tmp/latexmd_icon.png"
fi

# Generate all required sizes
for size in 16 32 64 128 256 512 1024; do
    sips -z $size $size "$BASE_PNG" --out "$ICONSET/icon_${size}x${size}.png" 2>/dev/null
done

# Generate @2x variants
sips -z 32 32 "$BASE_PNG" --out "$ICONSET/icon_16x16@2x.png" 2>/dev/null
sips -z 64 64 "$BASE_PNG" --out "$ICONSET/icon_32x32@2x.png" 2>/dev/null
sips -z 256 256 "$BASE_PNG" --out "$ICONSET/icon_128x128@2x.png" 2>/dev/null
sips -z 512 512 "$BASE_PNG" --out "$ICONSET/icon_256x256@2x.png" 2>/dev/null
sips -z 1024 1024 "$BASE_PNG" --out "$ICONSET/icon_512x512@2x.png" 2>/dev/null

# Convert to .icns
iconutil -c icns "$ICONSET" -o Assets/AppIcon.icns
rm -rf "$ICONSET"

echo "✅ AppIcon.icns created"
