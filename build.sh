#!/bin/bash
# ─────────────────────────────────────────────────────────────
# HNTR AI Marketing Site — Build Script (v3.33.0)
#
# Assembles HTML pages from src/ templates + _includes/ partials.
# Replaces <!-- HEADER --> and <!-- FOOTER --> markers with
# the contents of _includes/header.html and _includes/footer.html.
#
# For HEADER: also handles ACTIVE_NAV markers so the current page
# gets class="active" on its nav link.
#
# Usage:  ./build.sh
# Output: Assembled HTML files in project root (index.html, etc.)
# ─────────────────────────────────────────────────────────────

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SRC_DIR="$SCRIPT_DIR/src"
INCLUDES_DIR="$SCRIPT_DIR/_includes"
OUT_DIR="$SCRIPT_DIR"

HEADER_FILE="$INCLUDES_DIR/header.html"
FOOTER_FILE="$INCLUDES_DIR/footer.html"

if [ ! -f "$HEADER_FILE" ]; then echo "ERROR: Missing $HEADER_FILE"; exit 1; fi
if [ ! -f "$FOOTER_FILE" ]; then echo "ERROR: Missing $FOOTER_FILE"; exit 1; fi

# Map page filename to its ACTIVE_NAV key (macOS bash 3 compatible)
get_nav_key() {
  case "$1" in
    product.html)      echo "product" ;;
    about.html)        echo "about" ;;
    contact.html)      echo "contact" ;;
    architecture.html) echo "architecture" ;;
    *)                 echo "" ;;
  esac
}

count=0

for src_file in "$SRC_DIR"/*.html; do
  filename=$(basename "$src_file")
  out_file="$OUT_DIR/$filename"
  nav_key=$(get_nav_key "$filename")

  # Create a temp header with active nav for this page
  tmp_header=$(mktemp)
  cp "$HEADER_FILE" "$tmp_header"
  if [ -n "$nav_key" ]; then
    # Replace the ACTIVE_NAV marker for this page with class="active"
    sed -i '' "s/<!-- ACTIVE_NAV:${nav_key} -->/ class=\"active\"/g" "$tmp_header"
  fi
  # Remove remaining ACTIVE_NAV markers (non-active pages)
  sed -i '' 's/<!-- ACTIVE_NAV:[a-z_-]* -->//g' "$tmp_header"

  # Build the output file line by line, replacing markers with includes
  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in
      *"<!-- HEADER -->"*)
        cat "$tmp_header"
        ;;
      *"<!-- FOOTER -->"*)
        cat "$FOOTER_FILE"
        ;;
      *)
        printf '%s\n' "$line"
        ;;
    esac
  done < "$src_file" > "$out_file"

  rm -f "$tmp_header"
  count=$((count + 1))
  echo "  ✓ $filename"
done

echo ""
echo "Built $count pages from src/ → root"
echo "Header: $HEADER_FILE"
echo "Footer: $FOOTER_FILE"
