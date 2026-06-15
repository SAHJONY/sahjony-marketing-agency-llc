#!/usr/bin/env bash
# ------------------------------------------------------------
# Generate a marketing site from the generic template.
# It copies the template files into the ./site directory and
# replaces {{PLACEHOLDER}} tokens with environment variables or
# sensible defaults.
# ------------------------------------------------------------
set -euo pipefail

TEMPLATE_DIR="$(dirname "$0")/../template/site"
TARGET_DIR="$(dirname "$0")/../site"

# Ensure target exists (clean it first)
rm -rf "$TARGET_DIR"
mkdir -p "$TARGET_DIR"

# Copy everything
cp -R "$TEMPLATE_DIR"/* "$TARGET_DIR/"

# Helper for token replacement (uses env vars if set, otherwise fallback)
replace() {
  local token="$1"
  local value="${2:-}" # fallback value optional
  if [ -z "$value" ]; then
    # try to read from env
    value=$(printenv "$token" || true)
  fi
  # default to empty string if still missing
  value=${value:-}
  # escape slashes for sed
  esc_value=$(printf '%s' "$value" | sed -e 's/[\\/&]/\\\\&/g')
  sed -i '' "s|{{${token}}}|$esc_value|g" "$TARGET_DIR/index.html"
}


# Tokens we support (add more as needed)
replace BRAND_NAME
replace TAGLINE
replace PRIMARY_COLOR "#0a84ff"
replace CTA_LINK "#"
replace IMG_FEATURE_1 "https://via.placeholder.com/64"
replace IMG_FEATURE_2 "https://via.placeholder.com/64"
replace IMG_FEATURE_3 "https://via.placeholder.com/64"
replace FEATURE_TITLE_1 "Feature One"
replace FEATURE_DESC_1 "A short description of feature one."
replace FEATURE_TITLE_2 "Feature Two"
replace FEATURE_DESC_2 "A short description of feature two."
replace FEATURE_TITLE_3 "Feature Three"
replace FEATURE_DESC_3 "A short description of feature three."
replace CURRENT_YEAR "$(date +%Y)"

# Pricing blocks – we generate a simple placeholder if user provides a JSON file
if [ -f "../site/pricing.json" ]; then
  # Read JSON and create HTML blocks (very naive – assumes the same structure as before)
  PRICING_HTML=$(python3 - <<PY
import json, sys
p = json.load(open('../site/pricing.json'))
for tier in p['tiers']:
    name = tier['name']
    price = tier['price']
    feats = "".join(f"<li>{f}</li>" for f in tier['features'])
    cta = tier['cta']
    print(f'''<div class="p-6 border border-gray-300 rounded-lg bg-white">
        <h3 class="text-xl font-semibold mb-2">{name}</h3>
        <p class="text-2xl font-bold mb-4">${price}</p>
        <ul class="mb-4 text-left list-disc list-inside">{feats}</ul>
        <a href="{cta}" class="inline-block bg-primary text-white py-2 px-4 rounded">Select</a>
      </div>''')
PY
)
    # Escape for sed
    esc=$(printf '%s' "$PRICING_HTML" | sed -e 's/[\/&]/\\&/g')
    sed -i '' "s|{{PRICING_BLOCKS}}|$esc|g" "$TARGET_DIR/index.html"
else
    sed -i '' "s|{{PRICING_BLOCKS}}||g" "$TARGET_DIR/index.html"
fi

echo "Site generated in $TARGET_DIR"
