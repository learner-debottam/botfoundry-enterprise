# BotFoundry Enterprise

BotFoundry Enterprise is an **internal platform** for defining and deploying **Amazon Lex V2** conversational bots in a **GitOps-friendly monorepo**. The goal is to keep the **authoring surface small**: developers scaffold a package, then spend most of their time editing **`bot-config.json`** instead of Terraform.

---

## What you get

| Area | What BotFoundry provides |
|------|---------------------------|
| **Scaffolding** | CLI that copies **with-lambda** or **without-lambda** Terraform + optional Lambda boilerplate into `packages/<bot-name>/`. |
| **Configuration** | Single **`bot-config.json`** per bot (locales, intents, slots, prompts, optional Lambda names). |
| **Validation** | JSON Schema (`schemas/lex-bot-schema.json`) and scripts under `scripts/` for CI and local checks. |
| **Infrastructure** | Shared Terraform **modules** (`lexv2models`, `lambda`, logging) and per-package `infra/` with remote state. |
| **Delivery** | GitHub Actions on `main`: Release Please (per-package versions), Node checks, Terraform plan/apply, Lambda zip upload to S3 when applicable. |

---

## Developer workflow

### 1. Create a new bot package

From the repo root:

```bash
cd tools/create-bot
npm install
npm run dev
```

The CLI asks for:

- **Bot name** (alphanumeric, `-`, `_`) — becomes `packages/<bot-name>/`.
- **Template**: `with-lambda` or `without-lambda`.

It copies `templates/<template>/` into your package, generates a starter **`bot-config.json`**, and for `with-lambda` creates **`lambdas/<name>/`** stubs for each `fulfillment_lambda_name` it finds in that JSON.

### 2. Configure the bot

Edit **`packages/<bot-name>/bot-config.json`**:

- Add locales, slot types, intents, slots, utterances, prompts.
- For Lambda fulfillment, set **`fulfillment_lambda_name`** (and optionally **`lambda_config`**) on intents; names must match folders under `lambdas/` and the artifacts CI uploads (`<name>.zip`).

Validate against the schema when needed:

```bash
npx --yes ajv-cli validate -s schemas/lex-bot-schema.json -d packages/<bot-name>/bot-config.json --strict=false
```

Or use `scripts/validate-bot-config.sh` (see script header for usage).

### 3. Wire Terraform variables and deploy

Each package’s **`infra/`** reads **`../bot-config.json`** via `locals.tf`. Environment-specific values (account, region, S3 bucket for Lambdas, etc.) come from **`infra/vars/<env>.tfvars`** at the repo root.

Local example (adjust backend and vars to your setup):

```bash
cd packages/<bot-name>/infra
terraform init \
  -backend-config="bucket=YOUR_STATE_BUCKET" \
  -backend-config="key=<bot-name>/terraform.tfstate" \
  -backend-config="region=YOUR_REGION" \
  -backend-config="dynamodb_table=YOUR_LOCK_TABLE" \
  -reconfigure

terraform plan -var-file="../../../infra/vars/dev.tfvars"
```

On **push to `main`**, `.github/workflows/ci.yml` plans/applies changed packages and uploads Lambda zips when `bot-config.json` declares Lambdas.

---

## Repository layout

```
botfoundry-enterprise/
├── .github/workflows/     # Main CI + Release Please; PR validation workflow
├── docs/                  # (optional) add runbooks here
├── infra/vars/            # Shared *.tfvars per environment (dev, prod, …)
├── modules/
│   ├── cloudwatch-log-group/
│   ├── lambda/            # Lambda functions from S3 artifacts
│   └── lexv2models/       # Bot, locales, intents, slots, slot types, IAM, Lambda permissions
├── packages/              # One deployable bot per folder (insurance-bot, pizza-order-bot, …)
│   └── <bot>/
│       ├── bot-config.json
│       ├── infra/         # Root module for this bot
│       └── lambdas/       # Optional; present for with-lambda bots
├── schemas/
│   └── lex-bot-schema.json        # Lex bot JSON Schema
├── scripts/               # validate-bot-config.sh, validate-lambda-links.sh
├── templates/
│   ├── with-lambda/       # Terraform + sample bot-config pattern
│   └── without-lambda/
├── tools/create-bot/      # Scaffolding CLI (npm run dev)
├── .release-please-config.json
├── .release-please-manifest.json
└── README.md              # This file
```

---

## Terraform modules (conceptual)

### `modules/lexv2models`

Creates Lex V2 **Model** resources from decoded **`bot_config`**:

- `aws_lexv2models_bot`, `aws_lexv2models_bot_locale`
- `aws_lexv2models_intent`, `aws_lexv2models_slot_type`, `aws_lexv2models_slot`
- Lex service **IAM role** (Polly, CloudWatch logs, conditional Lambda invoke)
- **`aws_lambda_permission`** so Lex can invoke functions passed in as **`lambda_functions`** / **`lambda_arns`**

Intents, hooks, and prompts are driven from JSON; **`lambda_arns_effective`** merges **`lambda_functions`** (typical) with optional **`lambda_arns`**.

**Note:** `aws_lexv2models_bot_version` is present in the provider but **currently commented out** in `modules/lexv2models/main.tf`. There is a **`create_version`** variable in `variables.tf` intended to gate a version resource—today you should treat **DRAFT** as the Terraform-managed surface unless you re-enable versioning deliberately (see *Operational gaps* below).

### `modules/lambda`

Deploys Lambdas from **S3** (`s3_key` / `s3_bucket`), matching the CI job that builds and uploads **`*.zip`** per logical function name.

### `modules/cloudwatch-log-group`

Shared log groups for Lex and/or Lambda with retention and optional **`prevent_destroy`** in production.

---

## CI/CD (summary)

| Workflow | Purpose |
|----------|---------|
| **`ci.yml`** (`main`) | Release Please (per-package, manifest mode), change detection under `packages/*`, Node jobs for `package.json` trees, Terraform plan/apply per package × env, Lambda artifact upload when config references Lambdas. |
| **`pr-ci.yml`** | PR validation: Node + Terraform plan, artifact upload for plans. |

**AWS access:** OIDC + `AWS_ROLE_TO_ASSUME` / env-specific role secrets (see workflow comments).

**Releases:** [Release Please](https://github.com/googleapis/release-please/blob/main/docs/manifest-releaser.md) with `.release-please-config.json` and `.release-please-manifest.json` — register new packages there when you add bots you want versioned.

---

## AWS Lex V2 + Terraform: what is (and is not) fully automated

Lex **Runtime** concerns (aliases, published versions pointed to by production traffic, locale builds, custom vocabulary, some association workflows) **lag** behind what the **Models** Terraform resources cover, or have **no first-class resource** in the HashiCorp AWS provider yet.

### Covered well by Terraform (Models)

- Bot definition, locales, NLU model structure (intents, slots, slot types) as code from JSON.
- IAM for Lex (Polly, logging, Lambda invoke for known ARNs).
- Lambda **invoke permissions** for Lex (module uses default **`TSTALIASID`** test alias ARN shape for `aws_lambda_permission.source_arn`; override via **`lex_bot_alias_id`** when you standardize on another alias id).

### Often still manual or via AWS CLI / separate automation

| Concern | Typical reality today | Practical next step |
|---------|----------------------|---------------------|
| **Locale NLU build** | Terraform updates DRAFT; **building** the locale model so NLU is trained may require **console** or **`build-bot-locale`** (Lex V2 API) after changes. | Add a small **post-apply script** (AWS CLI) or Step Functions / CodeBuild job triggered after Terraform. |
| **Bot version + “live” alias** | `aws_lexv2models_bot_version` exists; **managed aliases** that customers call (e.g. production alias → stable version) are **not** fully replaced by a single well-supported **`aws_lexv2models_bot_alias`** story in all provider versions—teams often use **Console**, **CLI**, or **CloudFormation** for alias/version wiring. | Re-enable **`aws_lexv2models_bot_version`** behind **`create_version`**, output version id, then automate **CreateBotAlias** / **UpdateAlias** via CLI until provider coverage matches your needs. Track [provider issues and docs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lexv2models_bot). |
| **Custom vocabulary** | Usually separate **Lex V2 feature set**; may not map 1:1 to the same Terraform resources you use for intents. | Treat vocabulary as **optional module** or **runbook**; call Vocabulary APIs from automation if you need GitOps. |
| **Per-locale Lambda association nuance** | Models JSON + module map Lambdas to intents; **runtime alias** configuration in the console can still differ from what you expect until aliases/versions align. | Document **one** golden path: e.g. DRAFT + test alias for dev; version + named alias for prod, with explicit runbook steps. |

This README is intentionally honest so you can budget **runbooks** and **follow-up automation** rather than assuming `terraform apply` alone equals a production Lex endpoint.

---

## Improvement backlog (codebase-focused)

High value, low ambiguity:

1. **Wire `create_version`** to a real `aws_lexv2models_bot_version` resource (optional `count` / `lifecycle`) and expose **`bot_arn` + version id** outputs for downstream scripts.
2. **Scaffold quality:** Align **`tools/create-bot`** starter JSON with **`schemas/lex-bot-schema.json`** (e.g. `intent_type`, `sample_utterances`, `lambda_config` for with-lambda) so new packages validate without hand-fixing.
3. **Post-deploy automation:** Add `scripts/` or `docs/runbooks/` with AWS CLI examples: build locale, create/update alias, point alias at version—parameterized from Terraform outputs.
4. **`lex_bot_alias_id`:** Document per-environment values; avoid relying on **`TSTALIASID`** alone for production.
5. **Provider drift:** Periodically re-check Terraform AWS provider for **`lexv2models`** alias / vocabulary resources and collapse manual steps when stable.
6. **Root dev ergonomics:** Optional workspace **`package.json`** with a **`create-bot`** script that delegates to `tools/create-bot` so `npm run dev` is discoverable from the monorepo root.

---

## Contributing and versioning

- Use **Conventional Commits** on changes that should drive [Release Please](https://github.com/googleapis/release-please) bumps (`feat`, `fix`, etc.).
- Keep **`bot-config.json`** changes schema-valid; CI and reviewers should treat schema failures as merge blockers.
- Register new **`packages/<name>`** in **`.release-please-config.json`** and **`.release-please-manifest.json`** when that bot should be versioned as its own component.

---

## References

- [Amazon Lex V2 documentation](https://docs.aws.amazon.com/lexv2/latest/dg/what-is.html) (Models vs runtime, building locales, aliases, versions)
- [Terraform AWS provider — Lex V2 Models resources](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lexv2models_bot)
- [Conventional Commits](https://www.conventionalcommits.org/)

---

## License and support

Internal product repository; add your org’s license and support contacts here as appropriate.
