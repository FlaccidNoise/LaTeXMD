APP_NAME = LaTeXMD
BUILD_DIR = .build/release
BUNDLE = $(BUILD_DIR)/$(APP_NAME).app
DMG_NAME = $(APP_NAME).dmg
INSTALL_DIR = /Applications

.PHONY: all build bundle sign run install dmg icon clean help

all: build bundle sign
	@echo "✅ $(APP_NAME).app ready at $(BUNDLE)"

help:
	@echo "LaTeXMD Build Targets:"
	@echo "  make          — build + bundle + sign"
	@echo "  make run      — build + open for testing"
	@echo "  make install  — copy to /Applications"
	@echo "  make dmg      — create $(DMG_NAME) installer"
	@echo "  make icon     — regenerate app icon"
	@echo "  make clean    — remove build artifacts"

build:
	@echo "🔨 Building..."
	swift build -c release

bundle: build
	@echo "📦 Creating app bundle..."
	@mkdir -p "$(BUNDLE)/Contents/MacOS"
	@mkdir -p "$(BUNDLE)/Contents/Resources"
	@cp "$(BUILD_DIR)/$(APP_NAME)" "$(BUNDLE)/Contents/MacOS/$(APP_NAME)"
	@cp Info.plist "$(BUNDLE)/Contents/Info.plist"
	@if [ -f Assets/AppIcon.icns ]; then \
		cp Assets/AppIcon.icns "$(BUNDLE)/Contents/Resources/AppIcon.icns"; \
	fi

sign: bundle
	@echo "🔏 Signing..."
	@codesign --force --deep --sign - "$(BUNDLE)" 2>/dev/null || echo "⚠️  Ad-hoc signing (no Developer ID)"

run: all
	@echo "🚀 Launching..."
	@open "$(BUNDLE)"

install: all
	@echo "📲 Installing to $(INSTALL_DIR)..."
	@cp -R "$(BUNDLE)" "$(INSTALL_DIR)/$(APP_NAME).app"
	@echo "✅ Installed to $(INSTALL_DIR)/$(APP_NAME).app"

dmg: all
	@echo "💿 Creating DMG..."
	@rm -rf .build/dmg
	@mkdir -p .build/dmg
	@cp -R "$(BUNDLE)" .build/dmg/
	@ln -s /Applications .build/dmg/Applications
	@hdiutil create -volname "$(APP_NAME)" \
		-srcfolder .build/dmg \
		-ov -format UDZO \
		"$(BUILD_DIR)/$(DMG_NAME)" 2>/dev/null
	@rm -rf .build/dmg
	@echo "✅ DMG ready at $(BUILD_DIR)/$(DMG_NAME)"

icon:
	@echo "🎨 Generating app icon..."
	@bash generate_icon.sh
	@echo "✅ Icon generated at Assets/AppIcon.icns"

clean:
	@echo "🧹 Cleaning..."
	@swift package clean
	@rm -rf .build
	@echo "✅ Clean"
