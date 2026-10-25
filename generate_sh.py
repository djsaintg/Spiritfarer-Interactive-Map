#!/usr/bin/env python3
"""Regenerates spiritfarer_map.sh with all current source files embedded."""
import os

DIR = os.path.dirname(os.path.abspath(__file__))
DELIM = "SPIRITFARER_EOF"

def read(rel):
    with open(os.path.join(DIR, rel), encoding="utf-8") as f:
        return f.read().rstrip("\n")

# ── Collect project files ───────────────────────────────────────────────────
files = ["package.json", "tsconfig.json", "index.html", "vite.config.ts"]
for root, _, names in os.walk(os.path.join(DIR, "src")):
    for n in sorted(names):
        files.append(os.path.relpath(os.path.join(root, n), DIR))
dirs = sorted({os.path.dirname(f) for f in files if os.path.dirname(f)})

for f in files:
    assert f"\n{DELIM}\n" not in f"\n{read(f)}\n", f"{f} contains the heredoc delimiter"

# ── Build the shell script ──────────────────────────────────────────────────
sh = r'''#!/usr/bin/env bash

# ─── Spiritfarer — Everlight Atlas ───────────────────────────────────────────
# Interactive island map + quest log for Spiritfarer (unofficial fan tool).
# "ld.so: libextest.so cannot be preloaded" messages are a harmless system
# quirk and can safely be ignored.
# ─────────────────────────────────────────────────────────────────────────────

set -e

PROJECT_DIR="$HOME/spiritfarer-map"
mkdir -p "$PROJECT_DIR"
cd "$PROJECT_DIR"

echo ""
echo "📁  Project directory: $PROJECT_DIR"
echo ""

# ── Load nvm ──────────────────────────────────────────────────────────────────
export NVM_DIR="$HOME/.nvm"
if [ -s "$NVM_DIR/nvm.sh" ]; then
  \. "$NVM_DIR/nvm.sh"
fi

# ── Install Node.js if missing ────────────────────────────────────────────────
if ! command -v node &>/dev/null; then
  echo "⚠️   Node.js not found. Installing via nvm..."
  if command -v curl &>/dev/null; then
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
  elif command -v wget &>/dev/null; then
    wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
  else
    echo "❌  Neither curl nor wget found. Install Node.js from https://nodejs.org"
    exit 1
  fi
  \. "$NVM_DIR/nvm.sh"
  nvm install --lts
  nvm use --lts
fi

echo "✅  Node $(node --version)  /  npm $(npm --version)"
echo ""
echo "📝  Writing project files..."

'''
sh += "\n".join(f'mkdir -p "{d}"' for d in dirs) + "\n\n"

def sh_cat(name, content):
    return f"cat > \"{name}\" << '{DELIM}'\n{content}\n{DELIM}\n\n"

for f in files:
    sh += sh_cat(f, read(f))

# ── Build & launch section ───────────────────────────────────────────────────
sh += r'''# ── Install & Build ───────────────────────────────────────────────────────────
echo "📦  Installing project dependencies..."
npm install 2>/dev/null

echo ""
echo "🔨  Building..."
npm run build 2>/dev/null

OUTPUT="$PROJECT_DIR/dist/index.html"
if [ ! -f "$OUTPUT" ]; then
  echo "❌  Build failed — dist/index.html not found. Run 'npm run build' in $PROJECT_DIR to see why."
  exit 1
fi

echo ""
echo "✅  Build complete!"
echo ""

# ── Launch in a standalone GUI window ────────────────────────────────────────
APP_TITLE="Spiritfarer — Everlight Atlas"
FILE_URI="file://$OUTPUT"

launch_chromium_app() {
  local bin=$1
  "$bin" --app="$FILE_URI" --name="$APP_TITLE" \
    --no-first-run --no-default-browser-check \
    --disable-extensions --disable-translate --disable-infobars \
    --window-size=1500,950 2>/dev/null &
}

launch_gtk_window() {
  local py="$PROJECT_DIR/launcher.py"
  cat > "$py" << 'PYEOF'
#!/usr/bin/env python3
import gi, sys, os
gi.require_version('Gtk', '3.0')
gi.require_version('WebKit2', '4.0')
from gi.repository import Gtk, WebKit2
win = Gtk.Window()
win.set_title("Spiritfarer — Everlight Atlas")
win.set_default_size(1500, 950)
win.set_position(Gtk.WindowPosition.CENTER)
try: win.set_icon_name("applications-games")
except: pass
win.connect("destroy", Gtk.main_quit)
webview = WebKit2.WebView()
settings = webview.get_settings()
settings.set_enable_javascript(True)
webview.load_uri("file://" + os.path.abspath(sys.argv[1]))
win.add(webview)
win.show_all()
Gtk.main()
PYEOF
  python3 "$py" "$OUTPUT" 2>/dev/null &
}

echo "🖥️   Launching standalone GUI window..."

if command -v chromium-browser &>/dev/null; then launch_chromium_app "chromium-browser"
elif command -v chromium &>/dev/null; then launch_chromium_app "chromium"
elif command -v google-chrome &>/dev/null; then launch_chromium_app "google-chrome"
elif command -v google-chrome-stable &>/dev/null; then launch_chromium_app "google-chrome-stable"
elif python3 -c "import gi; gi.require_version('WebKit2','4.0'); from gi.repository import WebKit2" 2>/dev/null; then launch_gtk_window
elif command -v firefox &>/dev/null; then firefox "$FILE_URI" 2>/dev/null &
elif flatpak info org.mozilla.firefox &>/dev/null; then flatpak run --filesystem="$PROJECT_DIR/dist:ro" org.mozilla.firefox "$FILE_URI" 2>/dev/null &
elif command -v xdg-open &>/dev/null; then xdg-open "$OUTPUT" 2>/dev/null &
else echo "⚠️   No browser found. Open manually: $OUTPUT"
fi

echo "✅  Done!"
'''

out = os.path.join(DIR, "spiritfarer_map.sh")
with open(out, "w", encoding="utf-8") as f:
    f.write(sh)
os.chmod(out, 0o755)
print(f"✅  Written spiritfarer_map.sh ({len(files)} files embedded)")
