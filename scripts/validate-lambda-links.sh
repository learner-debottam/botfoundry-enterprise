# #!/bin/bash
# set -e

# echo "🔗 Validating Lambda references inside bot configs..."

# FAILED=0

# #############################################
# # Detect changed packages
# #############################################

# if [ -n "$GITHUB_BASE_REF" ]; then
#   git fetch origin $GITHUB_BASE_REF --depth=1
#   CHANGED_FILES=$(git diff --name-only origin/$GITHUB_BASE_REF HEAD)
# else
#   CHANGED_FILES=$(git diff --name-only HEAD~1 HEAD)
# fi

# PACKAGES=$(echo "$CHANGED_FILES" | grep '^packages/' | cut -d'/' -f2 | sort -u)

# for pkg in $PACKAGES; do

#   CONFIG_FILE="packages/$pkg/bot-config.json"

#   if [ ! -f "$CONFIG_FILE" ]; then
#     continue
#   fi

#   echo "➡️ Checking lambdas for $pkg"

#   #############################################
#   # Extract lambda names using jq
#   #############################################

#   LAMBDAS=$(jq -r '
#     .locales[]?.intents[]? |
#     .fulfillment_lambda_name?,
#     .lambda_config.function_name?
#   ' "$CONFIG_FILE" | sort -u | grep -v null || true)

#   for lambda in $LAMBDAS; do

#     LAMBDA_PATH="packages/$pkg/$lambda"

#     if [ ! -d "$LAMBDA_PATH" ]; then
#       echo "❌ Lambda folder missing: $lambda in $pkg"
#       FAILED=1
#     elif [ ! -f "$LAMBDA_PATH/package.json" ]; then
#       echo "❌ package.json missing in lambda: $lambda"
#       FAILED=1
#     else
#       echo "✅ Lambda exists: $lambda"
#     fi

#   done

# done

# if [ $FAILED -eq 1 ]; then
#   echo "❌ Lambda validation failed"
#   exit 1
# fi

# echo "🎉 All lambda references are valid!"

#!/bin/bash
set -euo pipefail

echo "🔗 Validating Lambda references inside bot configs..."

FAILED=0

if [ -n "${GITHUB_BASE_REF:-}" ]; then
  git fetch origin "$GITHUB_BASE_REF" --depth=1
  CHANGED_FILES=$(git diff --name-only "origin/$GITHUB_BASE_REF" HEAD)
else
  CHANGED_FILES=$(git diff --name-only HEAD~1 HEAD)
fi

PACKAGES=$(echo "$CHANGED_FILES" | grep '^packages/' | cut -d'/' -f2 | sort -u || true)

for pkg in $PACKAGES; do
  CONFIG_FILE="packages/$pkg/bot-config.json"
  [ -f "$CONFIG_FILE" ] || continue

  echo "➡️ Checking lambdas for $pkg"

  LAMBDAS=$(jq -r '
    .locales[]?.intents[]? | .fulfillment_lambda_name?, .lambda_config.function_name? 
  ' "$CONFIG_FILE" | sort -u | grep -v null || true)

  for lambda in $LAMBDAS; do
    LAMBDA_PATH="packages/$pkg/lambdas/$lambda"
    if [ ! -d "$LAMBDA_PATH" ]; then
      echo "❌ Lambda folder missing: $lambda in $pkg"
      FAILED=1
    elif [ ! -f "$LAMBDA_PATH/package.json" ]; then
      echo "❌ package.json missing in lambda: $lambda"
      FAILED=1
    else
      echo "✅ Lambda exists: $lambda"
    fi
  done
done

if [ $FAILED -eq 1 ]; then
  echo "❌ Lambda validation failed"
  exit 1
fi

echo "🎉 All lambda references are valid!"