#!/usr/bin/env bash
# Build all how-to bundles and generate the site
set -e

HOWTO_DIR="$(cd "$(dirname "$0")" && pwd)"
SITE_DIR="$HOWTO_DIR/site"

mkdir -p "$SITE_DIR"

# Build each how-to
for dir in "$HOWTO_DIR"/*/; do
  name=$(basename "$dir")
  [ "$name" = "site" ] && continue
  [ "$name" = ".git" ] && continue
  [ ! -f "$dir/spago.yaml" ] && continue

  echo "Building $name..."
  (cd "$dir" && npx spago build && npx spago bundle -p "$name" 2>/dev/null || npx spago bundle)

  # Copy bundle and HTML to site
  mkdir -p "$SITE_DIR/$name"
  cp "$dir/public/bundle.js" "$SITE_DIR/$name/"
  cp "$dir/public/index.html" "$SITE_DIR/$name/"
done

# Generate the index page with embedded source
echo "Generating index..."
node "$HOWTO_DIR/gen-index.mjs"

echo "Done! Site at $SITE_DIR/"
