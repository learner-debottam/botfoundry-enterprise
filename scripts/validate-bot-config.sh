# #!/bin/bash
# set -e

# echo "🔍 Smart Lex Bot Config Validation Started..."

# SCHEMA_FILE="schemas/lex-bot-schema.json"

# if [ ! -f "$SCHEMA_FILE" ]; then
#   echo "❌ Schema file not found: $SCHEMA_FILE"
#   exit 1
# fi

# #############################################
# # Detect changed files
# #############################################

# if [ -n "$GITHUB_BASE_REF" ]; then
#   echo "📦 PR detected: comparing with origin/$GITHUB_BASE_REF"
#   git fetch origin $GITHUB_BASE_REF --depth=1
#   CHANGED_FILES=$(git diff --name-only origin/$GITHUB_BASE_REF HEAD)
# else
#   echo "📦 Push detected: comparing last commit"
#   CHANGED_FILES=$(git diff --name-only HEAD~1 HEAD)
# fi

# #############################################
# # Detect affected packages
# #############################################

# PACKAGES=$(echo "$CHANGED_FILES" | grep '^packages/' | cut -d'/' -f2 | sort -u)

# if [ -z "$PACKAGES" ]; then
#   echo "⏭️ No package changes detected. Skipping validation."
#   exit 0
# fi

# echo "📦 Affected packages:"
# echo "$PACKAGES"

# FAILED=0

# #############################################
# # Validate config per affected package
# #############################################

# for pkg in $PACKAGES; do

#   CONFIG_FILE="packages/$pkg/bot-config.json"

#   if [ -f "$CONFIG_FILE" ]; then
#     echo "➡️ Validating $CONFIG_FILE (package: $pkg)"

#     if ! npx --yes ajv-cli validate \
#         -s "$SCHEMA_FILE" \
#         -d "$CONFIG_FILE" \
#         --strict=false; then

#       echo "❌ Validation failed for $CONFIG_FILE"
#       FAILED=1
#     else
#       echo "✅ Valid: $CONFIG_FILE"
#     fi

#   else
#     echo "⏭️ Package $pkg has no bot-config.json (skipped)"
#   fi

# done

# #############################################
# # Final result
# #############################################

# if [ $FAILED -eq 1 ]; then
#   echo "❌ One or more bot configs are invalid"
#   exit 1
# fi

# echo "🎉 All affected bot configs are valid!"

#!/bin/bash
set -euo pipefail

echo "🔍 Smart Lex Bot Config Validation Started..."

SCHEMA_FILE="schemas/lex-bot-schema.json"

if [ ! -f "$SCHEMA_FILE" ]; then
  echo "❌ Schema file not found: $SCHEMA_FILE"
  exit 1
fi

#############################################
# Detect changed files
#############################################
if [ -n "${GITHUB_BASE_REF:-}" ]; then
  echo "📦 PR detected: comparing with origin/$GITHUB_BASE_REF"
  git fetch origin "$GITHUB_BASE_REF" --depth=1
  CHANGED_FILES=$(git diff --name-only "origin/$GITHUB_BASE_REF" HEAD)
else
  echo "📦 Push detected: comparing last commit"
  CHANGED_FILES=$(git diff --name-only HEAD~1 HEAD)
fi

PACKAGES=$(echo "$CHANGED_FILES" | grep '^packages/' | cut -d'/' -f2 | sort -u || true)

if [ -z "$PACKAGES" ]; then
  echo "⏭️ No package changes detected. Skipping validation."
  exit 0
fi

echo "📦 Affected packages:"
echo "$PACKAGES"

FAILED=0

for pkg in $PACKAGES; do
  CONFIG_FILE="packages/$pkg/bot-config.json"
  if [ -f "$CONFIG_FILE" ]; then
    echo "➡️ Validating $CONFIG_FILE (package: $pkg)"
    if ! npx --yes ajv-cli validate -s "$SCHEMA_FILE" -d "$CONFIG_FILE" --strict=false; then
      echo "❌ Validation failed for $CONFIG_FILE"
      FAILED=1
    else
      echo "✅ Valid: $CONFIG_FILE"
    fi
  else
    echo "⏭️ Package $pkg has no bot-config.json (skipped)"
  fi
done

if [ $FAILED -eq 1 ]; then
  echo "❌ One or more bot configs are invalid"
  exit 1
fi

echo "🎉 All affected bot configs are valid!"