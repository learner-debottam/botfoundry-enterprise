# #!/bin/bash
# set -e

# ENV=$1

# echo "Deploying to $ENV"

# terraform -chdir=infra init -backend-config="state/${ENV}.config"
# terraform -chdir=infra apply \
#   -var-file="vars/${ENV}.tfvars" \
#   -auto-approve

#!/bin/bash
set -euo pipefail

ENV=${1:-}

if [ -z "$ENV" ]; then
  echo "❌ Usage: $0 <environment>"
  exit 1
fi

echo "🌐 Deploying Terraform for environment: $ENV"

# Check Terraform binary
if ! command -v terraform &>/dev/null; then
  echo "❌ Terraform not installed or not in PATH"
  exit 1
fi

STATE_FILE="infra/state/${ENV}.config"
VAR_FILE="infra/vars/${ENV}.tfvars"

if [ ! -f "$STATE_FILE" ]; then
  echo "❌ Terraform backend config missing: $STATE_FILE"
  exit 1
fi

if [ ! -f "$VAR_FILE" ]; then
  echo "❌ Terraform vars file missing: $VAR_FILE"
  exit 1
fi

echo "🔹 Initializing Terraform..."
terraform -chdir=infra init -backend-config="$STATE_FILE"

echo "🔹 Planning Terraform changes..."
terraform -chdir=infra plan -var-file="$VAR_FILE"

echo "🔹 Applying Terraform changes..."
terraform -chdir=infra apply -var-file="$VAR_FILE" -auto-approve

echo "✅ Deployment completed for $ENV"