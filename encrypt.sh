#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SRC_DIR="$SCRIPT_DIR/src"
OUT_DIR="$SCRIPT_DIR/docs"

if [ ! -d "$SRC_DIR" ]; then
  echo "No src/ directory found."
  exit 1
fi

# Count HTML files
html_files=("$SRC_DIR"/*.html)
if [ ! -e "${html_files[0]}" ]; then
  echo "No HTML files found in src/"
  exit 1
fi

echo "Encrypting ${#html_files[@]} file(s)..."

# Encrypt all HTML files from src/ into docs/
# Password is prompted interactively (or set STATICRYPT_PASSWORD env var)
npx staticrypt "${html_files[@]}" \
  -d "$OUT_DIR" \
  --short \
  --remember 30 \
  --label "claude-artifacts" \
  --template-title "Claude Artifact" \
  --template-instructions "Enter the password to view this artifact."

# Generate index.html listing all encrypted files
{
  cat <<'HEADER'
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>My Artifacts</title>
<style>
  body { font-family: system-ui, sans-serif; max-width: 600px; margin: 4rem auto; padding: 0 1rem; color: #333; }
  a { color: #0066cc; text-decoration: none; }
  a:hover { text-decoration: underline; }
  li { margin: 0.5rem 0; }
</style>
</head>
<body>
<h1>My Artifacts</h1>
<ul>
HEADER

  for f in "$OUT_DIR"/*.html; do
    name="$(basename "$f")"
    [ "$name" = "index.html" ] && continue
    label="${name%.html}"
    # Convert hyphens/underscores to spaces and title-case
    label="$(echo "$label" | sed 's/[-_]/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)}1')"
    echo "  <li><a href=\"$name\">$label</a></li>"
  done

  cat <<'FOOTER'
</ul>
</body>
</html>
FOOTER
} > "$OUT_DIR/index.html"

echo "Done! Encrypted files are in docs/"
echo "Index generated at docs/index.html"
