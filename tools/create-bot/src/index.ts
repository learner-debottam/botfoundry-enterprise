import inquirer from "inquirer";
import fs from "fs-extra";
import path from "path";

type BotType = "with-lambda" | "without-lambda";

interface LambdaIntent {
  fulfillment_lambda_name?: string;
}

interface Locale {
  intents: Record<string, LambdaIntent>;
}

interface BotConfig {
  name: string;
  idle_session_ttl: number;
  description?: string;
  type?: string;
  child_directed?: boolean;
  logging?: { enabled: boolean; log_level: string };
  locales: Record<string, Locale>;
}

(async () => {
  console.log("🚀 Welcome to Lex Bot Generator");

  const answers = await inquirer.prompt([
    {
      type: "input",
      name: "botName",
      message: "Enter bot name:",
      validate: (input) =>
        input.match(/^[A-Za-z0-9_-]+$/) ? true : "Only alphanumeric, - and _ allowed",
    },
    {
      type: "list",
      name: "botType",
      message: "Select bot type:",
      choices: ["with-lambda", "without-lambda"],
    },
  ]);

  const { botName, botType } = answers as { botName: string; botType: BotType };

  // -------------------------
  // Directories
  // -------------------------
  const projectRoot = path.resolve(__dirname, "../../.."); // botfoundry-enterprise root
  const packagesDir = path.join(projectRoot, "packages");
  const rootDir = path.join(packagesDir, botName);
  const infraDir = path.join(rootDir, "infra");
  const lambdasDir = path.join(rootDir, "lambdas");

  fs.ensureDirSync(rootDir);
  fs.ensureDirSync(infraDir);
  if (botType === "with-lambda") fs.ensureDirSync(lambdasDir);

  // -------------------------
  // Copy Terraform templates
  // -------------------------
  const templateDir = path.join(projectRoot, "templates", botType);
  if (!fs.existsSync(templateDir)) {
    console.error(`Template folder for '${botType}' not found at ${templateDir}`);
    process.exit(1);
  }

  fs.copySync(path.join(templateDir, "infra"), infraDir);
  console.log(`📂 Copied Terraform templates for ${botType}`);

  // -------------------------
  // Generate sample bot-config.json
  // -------------------------
  const botConfigPath = path.join(rootDir, "bot-config.json");
  if (!fs.existsSync(botConfigPath)) {
    const sampleBotConfig: BotConfig =
      botType === "without-lambda"
        ? {
            name: botName,
            idle_session_ttl: 300,
            locales: {
              en_US: { description: "English (US)", confidence_threshold: 0.75, intents: {} } as any,
            },
          }
        : {
            name: botName,
            description: "A banking assistant bot with Lambda integrations",
            type: "Bot",
            idle_session_ttl: 300,
            child_directed: false,
            logging: { enabled: true, log_level: "INFO" },
            locales: {
              en_US: {
                description: "English (US)",
                confidence_threshold: 0.75,
                intents: {
                  CheckBalance: {
                    fulfillment_lambda_name: "check_balance",
                  },
                  RecentTransactions: {
                    fulfillment_lambda_name: "recent_transactions",
                  },
                },
              } as Locale,
            },
          };
    fs.writeJsonSync(botConfigPath, sampleBotConfig, { spaces: 2 });
  }

  // -------------------------
  // Generate Lambda folders if with-lambda
  // -------------------------
  if (botType === "with-lambda") {
    const botConfig: BotConfig = fs.readJsonSync(botConfigPath);
    for (const locale of Object.values(botConfig.locales)) {
      for (const [intentName, intent] of Object.entries(locale.intents)) {
        if (intent.fulfillment_lambda_name) {
          const lambdaName = intent.fulfillment_lambda_name;
          const lambdaSrcDir = path.join(lambdasDir, lambdaName, "src");
          fs.ensureDirSync(lambdaSrcDir);

          // index.ts
          const indexPath = path.join(lambdaSrcDir, "index.ts");
          if (!fs.existsSync(indexPath)) {
            fs.writeFileSync(
              indexPath,
              `import { APIGatewayProxyHandler } from "aws-lambda";

export const handler: APIGatewayProxyHandler = async (event) => {
  console.log("Received event:", JSON.stringify(event, null, 2));
  return {
    statusCode: 200,
    body: JSON.stringify({ message: "Processed ${lambdaName} successfully", input: event }),
  };
};
`
            );
          }

          // package.json
          const pkgJsonPath = path.join(lambdasDir, lambdaName, "package.json");
          if (!fs.existsSync(pkgJsonPath)) {
            fs.writeJsonSync(
              pkgJsonPath,
              {
                name: lambdaName,
                version: "1.0.0",
                main: "dist/index.js",
                scripts: { build: "tsc", clean: "rm -rf dist", package: "npm run clean && npm run build" },
                dependencies: {},
                devDependencies: { "@types/aws-lambda": "^8.10.118", "@types/node": "^20.11.0", typescript: "^5.2.2" },
              },
              { spaces: 2 }
            );
          }

          // tsconfig.json
          const tsconfigPath = path.join(lambdasDir, lambdaName, "tsconfig.json");
          if (!fs.existsSync(tsconfigPath)) {
            fs.writeJsonSync(
              tsconfigPath,
              {
                compilerOptions: {
                  target: "ES2021",
                  module: "CommonJS",
                  outDir: "dist",
                  rootDir: "src",
                  strict: true,
                  esModuleInterop: true,
                  forceConsistentCasingInFileNames: true,
                },
                include: ["src/**/*"],
              },
              { spaces: 2 }
            );
          }
        }
      }
    }
  }

  console.log("\n✅ Bot created successfully at packages/" + botName);
})();
// import inquirer from "inquirer";
// import fs from "fs-extra";
// import path from "path";

// type BotType = "with-lambda" | "without-lambda";

// (async () => {
//   console.log("🚀 Welcome to Lex Bot Generator");

//   // -------------------------
//   // Prompt User
//   // -------------------------
//   const answers = await inquirer.prompt([
//     {
//       type: "input",
//       name: "botName",
//       message: "Enter bot name:",
//       validate: (input) =>
//         input.match(/^[A-Za-z0-9_-]+$/)
//           ? true
//           : "Only alphanumeric, - and _ allowed",
//     },
//     {
//       type: "list",
//       name: "botType",
//       message: "Select bot type:",
//       choices: ["with-lambda", "without-lambda"],
//     },
//   ]);

//   const { botName, botType } = answers as { botName: string; botType: BotType };

//   // -------------------------
//   // Determine root paths
//   // -------------------------
//   const projectRoot = path.resolve(__dirname, "../../.."); // Adjust if needed
//   const packagesDir = path.join(projectRoot, "packages");
//   const rootDir = path.join(packagesDir, botName);
//   const infraDir = path.join(rootDir, "infra");
//   const lambdasDir = path.join(rootDir, "lambdas");

//   fs.ensureDirSync(packagesDir);
//   fs.ensureDirSync(rootDir);
//   fs.ensureDirSync(infraDir);

//   // -------------------------
//   // Copy Terraform templates
//   // -------------------------
//   const templateDir = path.join(__dirname, "../../templates", botType);
//   if (!fs.existsSync(templateDir)) {
//     console.error(`Template folder for '${botType}' not found at ${templateDir}`);
//     process.exit(1);
//   }
//   fs.copySync(path.join(templateDir, "infra"), infraDir);
//   console.log(`📂 Copied Terraform templates for ${botType}`);

//   // -------------------------
//   // Generate bot-config.json
//   // -------------------------
//   const botConfigPath = path.join(rootDir, "bot-config.json");
//   if (!fs.existsSync(botConfigPath)) {
//     const sampleBotConfig =
//       botType === "without-lambda"
//         ? {
//             name: botName,
//             idle_session_ttl: 300,
//             locales: {
//               en_US: {
//                 description: "English (US)",
//                 confidence_threshold: 0.75,
//                 voice_settings: {
//                   voice_id: "Joanna",
//                   engine: "neural",
//                 },
//                 intents: {},
//               },
//             },
//           }
//         : {
//             name: botName,
//             description: `A ${botName} bot with Lambda integrations`,
//             type: "Bot",
//             idle_session_ttl: 300,
//             child_directed: false,
//             logging: { enabled: true, log_level: "INFO" },
//             locales: {
//               en_US: {
//                 description: "English (US)",
//                 confidence_threshold: 0.75,
//                 voice_settings: { voice_id: "Joanna", engine: "neural" },
//                 slot_types: {},
//                 intents: {
//                   CheckBalance: {
//                     intent_type: "Normal",
//                     sample_utterances: ["What is my balance?", "Check my balance"],
//                     fulfillment_lambda_name: "check_balance",
//                     lambda_config: { function_name: "check_balance", timeout_ms: 5000 },
//                   },
//                   RecentTransactions: {
//                     intent_type: "Normal",
//                     sample_utterances: ["Show recent transactions", "Recent activity"],
//                     fulfillment_lambda_name: "recent_transactions",
//                     lambda_config: { function_name: "recent_transactions", timeout_ms: 5000 },
//                   },
//                 },
//               },
//             },
//           };

//     fs.writeJsonSync(botConfigPath, sampleBotConfig, { spaces: 2 });
//     console.log("📝 Generated bot-config.json");
//   }

//   // -------------------------
//   // Generate Lambda folders & files
//   // -------------------------
//   if (botType === "with-lambda") {
//     fs.ensureDirSync(lambdasDir);
//     const botConfig = fs.readJsonSync(botConfigPath);

//     for (const locale of Object.values(botConfig.locales)) {
//       const intents = (locale as any).intents || {};
//       for (const [intentName, intent] of Object.entries(intents)) {
//         const lambdaName = (intent as any).fulfillment_lambda_name;
//         if (!lambdaName) continue;

//         const lambdaSrcDir = path.join(lambdasDir, lambdaName, "src");
//         fs.ensureDirSync(lambdaSrcDir);

//         // index.ts
//         const indexPath = path.join(lambdaSrcDir, "index.ts");
//         if (!fs.existsSync(indexPath)) {
//           fs.writeFileSync(
//             indexPath,
//             `import { APIGatewayProxyHandler } from "aws-lambda";

// export const handler: APIGatewayProxyHandler = async (event) => {
//   console.log("Received event:", JSON.stringify(event, null, 2));
//   return {
//     statusCode: 200,
//     body: JSON.stringify({ message: "Processed ${lambdaName} successfully", input: event })
//   };
// };
// `
//           );
//         }

//         // package.json
//         const pkgJsonPath = path.join(lambdasDir, lambdaName, "package.json");
//         if (!fs.existsSync(pkgJsonPath)) {
//           fs.writeJsonSync(
//             pkgJsonPath,
//             {
//               name: lambdaName,
//               version: "1.0.0",
//               main: "dist/index.js",
//               scripts: { build: "tsc", clean: "rm -rf dist", package: "npm run clean && npm run build" },
//               dependencies: {},
//               devDependencies: { "@types/aws-lambda": "^8.10.118", "@types/node": "^20.11.0", typescript: "^5.2.2" },
//             },
//             { spaces: 2 }
//           );
//         }

//         // tsconfig.json
//         const tsconfigPath = path.join(lambdasDir, lambdaName, "tsconfig.json");
//         if (!fs.existsSync(tsconfigPath)) {
//           fs.writeJsonSync(
//             tsconfigPath,
//             {
//               compilerOptions: {
//                 target: "ES2021",
//                 module: "CommonJS",
//                 outDir: "dist",
//                 rootDir: "src",
//                 strict: true,
//                 esModuleInterop: true,
//                 forceConsistentCasingInFileNames: true,
//               },
//               include: ["src/**/*"],
//             },
//             { spaces: 2 }
//           );
//         }
//       }
//     }

//     console.log("📦 Generated Lambda folders and files");
//   }

//   console.log(`\n✅ Bot '${botName}' created successfully in packages/${botName}`);
// })();
// // import inquirer from "inquirer";
// // import fs from "fs-extra";
// // import path from "path";

// // // -------------------------
// // // Type Definitions
// // // -------------------------
// // type BotType = "with-lambda" | "without-lambda";

// // interface LambdaConfig {
// //   function_name: string;
// //   timeout_ms: number;
// // }

// // interface LambdaIntent {
// //   fulfillment_lambda_name?: string;
// //   lambda_config?: LambdaConfig;
// //   sample_utterances?: string[];
// //   intent_type?: string;
// // }

// // interface Locale {
// //   description: string;
// //   confidence_threshold: number;
// //   voice_settings: { voice_id: string; engine: string };
// //   slot_types?: Record<string, unknown>;
// //   intents: Record<string, LambdaIntent>;
// // }

// // interface BotConfig {
// //   name: string;
// //   description?: string;
// //   type?: string;
// //   idle_session_ttl: number;
// //   child_directed?: boolean;
// //   logging?: { enabled: boolean; log_level: "INFO" | "ERROR" };
// //   locales: Record<string, Locale>;
// // }

// // // -------------------------
// // // Prompt User
// // // -------------------------
// // (async () => {
// //   console.log("🚀 Welcome to Lex Bot Generator");

// //   const answers = await inquirer.prompt([
// //     {
// //       type: "input",
// //       name: "botName",
// //       message: "Enter bot name:",
// //       validate: (input) =>
// //         /^[A-Za-z0-9_-]+$/.test(input)
// //           ? true
// //           : "Only alphanumeric characters, '-' and '_' are allowed",
// //     },
// //     {
// //       type: "list",
// //       name: "botType",
// //       message: "Select bot type:",
// //       choices: ["with-lambda", "without-lambda"],
// //     },
// //   ]);

// //   const { botName, botType } = answers as { botName: string; botType: BotType };

// //   // -------------------------
// //   // Define root paths
// //   // -------------------------
// //   // const rootDir = path.join(process.cwd(), "../packages", botName);
// //   // const infraDir = path.join(rootDir, "infra");
// //   // const lambdasDir = path.join(rootDir, "lambdas");

// //   const projectRoot = path.resolve(__dirname, "../../../"); // go up two levels to botfoundry-enterprise
// // const rootDir = path.join(projectRoot, "packages", botName);
// // const infraDir = path.join(rootDir, "infra");
// // const lambdasDir = path.join(rootDir, "lambdas");

// //   fs.ensureDirSync(infraDir);
// //   if (botType === "with-lambda") fs.ensureDirSync(lambdasDir);

// //   // -------------------------
// //   // Generate infra template files
// //   // -------------------------
// //   const infraFiles: Record<string, string> = {
// //     "variables.tf": `# ============================================================================
// // # Variables for ${botName} bot
// // # ============================================================================
// // variable "environment" { description = "Deployment environment"; type = string; default = "dev" }
// // variable "aws_region" { description = "AWS region"; type = string }
// // variable "aws_account_id" { description = "AWS account ID"; type = string }
// // variable "aws_account_name" { description = "AWS account name"; type = string }
// // variable "s3_bucket" { description = "S3 bucket for Lambda artifacts"; type = string }
// // `,
// //     "locals.tf":
// //       botType === "without-lambda"
// //         ? `locals {
// //   bot_config = jsondecode(file("${path.posix.join(
// //     infraDir,
// //     "../bot-config.json"
// //   )}"))
// //   bot_name   = local.bot_config.name
// //   polly_arn  = "arn:aws:polly:\${var.aws_region}:\${var.aws_account_id}:lexicon/*"

// //   tags = {
// //     MANAGED_BY       = "Terraform"
// //     ENVIRONMENT      = var.environment
// //     AWS_REGION       = var.aws_region
// //     AWS_ACCOUNT_NAME = var.aws_account_name
// //     AWS_ACCOUNT_ID   = var.aws_account_id
// //   }
// // }`
// //         : `locals {
// //   bot_config = jsondecode(file("${path.posix.join(
// //     infraDir,
// //     "../bot-config.json"
// //   )}"))
// //   bot_name   = local.bot_config.name
// //   namespace  = "\${var.aws_account_name}-\${var.environment}-\${local.bot_name}"
// //   polly_arn  = "arn:aws:polly:\${var.aws_region}:\${var.aws_account_id}:lexicon/*"

// //   intents = flatten([
// //     for locale, locale_data in local.bot_config.locales : [
// //       for intent_name, intent in locale_data.intents : merge(intent, {
// //         intent_name = intent_name
// //         locale      = locale
// //       })
// //     ]
// //   ])

// //   lambda_intents = [
// //     for intent in local.intents : intent
// //     if lookup(intent, "fulfillment_lambda_name", null) != null
// //   ]

// //   lambdas = {
// //     for intent in local.lambda_intents : intent.fulfillment_lambda_name => {
// //       namespace                      = local.namespace
// //       description                    = intent.description
// //       handler                        = "index.handler"
// //       runtime                        = "nodejs24.x"
// //       timeout                        = floor(lookup(intent.lambda_config, "timeout_ms", 3000) / 1000)
// //       memory_size                    = 1024
// //       kms_key_arn                    = null
// //       s3_key                         = "\${intent.fulfillment_lambda_name}.zip"
// //       s3_bucket                      = var.s3_bucket
// //       reserved_concurrent_executions = -1
// //       environment_variables = {
// //         INTENT_NAME = intent.fulfillment_lambda_name
// //       }
// //     }
// //   }

// //   tags = {
// //     MANAGED_BY       = "Terraform"
// //     ENVIRONMENT      = var.environment
// //     AWS_REGION       = var.aws_region
// //     AWS_ACCOUNT_NAME = var.aws_account_name
// //     AWS_ACCOUNT_ID   = var.aws_account_id
// //   }
// // }`,
// //     "versions.tf": `terraform {
// //   required_version = ">= 1.5.0"

// //   required_providers {
// //     aws = { source = "hashicorp/aws", version = ">= 6.20" }
// //   }
// // }`,
// //     "backend.tf": `terraform {
// //   backend "s3" {
// //     bucket         = "my-terraform-state-bucket"
// //     key            = "${botName}/terraform.tfstate"
// //     region         = "eu-west-2"
// //     dynamodb_table = "terraform-state-lock"
// //     encrypt        = true
// //   }
// // }`,
// //     "main.tf": botType === "without-lambda"
// //       ? `module "logs" {
// //   source = "../../../modules/cloudwatch-log-group"
// //   name              = "/aws/lex/\${local.bot_name}"
// //   retention_in_days = 365
// //   prevent_destroy   = var.environment == "prod"
// // }

// // module "lex" {
// //   source = "../../../modules/lexv2models"
// //   bot_config = local.bot_config
// //   cloudwatch_log_group_arn = module.logs.log_group_arn
// //   polly_arn = local.polly_arn
// //   lexv2_bot_role_name = "\${var.aws_account_name}-\${var.environment}-\${local.bot_name}-lex-iam-role"
// // }`
// //       : `# CloudWatch Logs
// // module "lex_logs" {
// //   source            = "../../../modules/cloudwatch-log-group"
// //   name              = "/aws/lex/\${local.bot_name}"
// //   retention_in_days = 365
// //   prevent_destroy   = var.environment == "prod"
// // }

// // module "lambda_logs" {
// //   source   = "../../../modules/cloudwatch-log-group"
// //   for_each = local.lambdas
// //   name              = "/aws/lambda/\${each.key}"
// //   retention_in_days = 365
// //   prevent_destroy   = var.environment == "prod"
// // }

// // # Lambdas
// // module "lambda" {
// //   source                  = "../../../modules/lambda"
// //   lambdas                 = local.lambdas
// //   prevent_destroy         = var.environment == "prod"
// //   lambda_artifacts_bucket = var.s3_bucket
// //   lambda_log_group_arns = { for k, v in module.lambda_logs : k => v.log_group_arn }
// // }

// // # Lex Bot
// // module "lex" {
// //   source = "../../../modules/lexv2models"
// //   bot_config = local.bot_config
// //   lambda_functions = { for k, v in module.lambda.functions : k => { function_name = v.function_name; arn = v.arn } }
// //   cloudwatch_log_group_arn = module.lex_logs.log_group_arn
// //   polly_arn                = local.polly_arn
// //   lexv2_bot_role_name      = "\${local.namespace}-lex-iam-role"
// //   depends_on = [module.lambda]
// // }`
// //   };

// //   // Write infra files
// //   Object.entries(infraFiles).forEach(([fileName, content]) => {
// //     fs.writeFileSync(path.join(infraDir, fileName), content);
// //   });

// //   // -------------------------
// //   // Generate sample bot-config.json
// //   // -------------------------
// //   const botConfigPath = path.join(rootDir, "bot-config.json");
// //   if (!fs.existsSync(botConfigPath)) {
// //     const sampleBotConfig: BotConfig =
// //       botType === "without-lambda"
// //         ? {
// //             name: botName,
// //             idle_session_ttl: 300,
// //             locales: {
// //               en_US: {
// //                 description: "English (US)",
// //                 confidence_threshold: 0.75,
// //                 voice_settings: { voice_id: "Joanna", engine: "neural" },
// //                 intents: {},
// //               },
// //             },
// //           }
// //         : {
// //             name: botName,
// //             description: "A banking assistant bot with Lambda integrations",
// //             type: "Bot",
// //             idle_session_ttl: 300,
// //             child_directed: false,
// //             logging: { enabled: true, log_level: "INFO" },
// //             locales: {
// //               en_US: {
// //                 description: "English (US)",
// //                 confidence_threshold: 0.75,
// //                 voice_settings: { voice_id: "Joanna", engine: "neural" },
// //                 slot_types: {},
// //                 intents: {
// //                   CheckBalance: {
// //                     intent_type: "Normal",
// //                     sample_utterances: ["What is my balance?", "Check my balance"],
// //                     fulfillment_lambda_name: "check_balance",
// //                     lambda_config: { function_name: "check_balance", timeout_ms: 5000 },
// //                   },
// //                   RecentTransactions: {
// //                     intent_type: "Normal",
// //                     sample_utterances: ["Show recent transactions", "Recent activity"],
// //                     fulfillment_lambda_name: "recent_transactions",
// //                     lambda_config: { function_name: "recent_transactions", timeout_ms: 5000 },
// //                   },
// //                 },
// //               },
// //             },
// //           };
// //     fs.writeJsonSync(botConfigPath, sampleBotConfig, { spaces: 2 });
// //   }

// //   // -------------------------
// //   // Generate Lambda folders if with-lambda
// //   // -------------------------
// //   if (botType === "with-lambda") {
// //     const botConfig = fs.readJsonSync(botConfigPath) as BotConfig;
// //     for (const locale of Object.values(botConfig.locales)) {
// //       const intents = locale.intents as Record<string, LambdaIntent>;
// //       for (const [intentName, intent] of Object.entries(intents)) {
// //         if (!intent.fulfillment_lambda_name) continue;

// //         const lambdaName = intent.fulfillment_lambda_name;
// //         const lambdaSrcDir = path.join(lambdasDir, lambdaName, "src");
// //         fs.ensureDirSync(lambdaSrcDir);

// //         // index.ts
// //         const indexPath = path.join(lambdaSrcDir, "index.ts");
// //         if (!fs.existsSync(indexPath)) {
// //           fs.writeFileSync(
// //             indexPath,
// //             `import { APIGatewayProxyHandler } from "aws-lambda";

// // export const handler: APIGatewayProxyHandler = async (event) => {
// //   console.log("Received event:", JSON.stringify(event, null, 2));
// //   return {
// //     statusCode: 200,
// //     body: JSON.stringify({ message: "Processed ${lambdaName} successfully", input: event }),
// //   };
// // };
// // `
// //           );
// //         }

// //         // package.json
// //         const pkgJsonPath = path.join(lambdasDir, lambdaName, "package.json");
// //         if (!fs.existsSync(pkgJsonPath)) {
// //           fs.writeJsonSync(
// //             pkgJsonPath,
// //             {
// //               name: lambdaName,
// //               version: "1.0.0",
// //               main: "dist/index.js",
// //               scripts: { build: "tsc", clean: "rm -rf dist", package: "npm run clean && npm run build" },
// //               dependencies: {},
// //               devDependencies: { "@types/aws-lambda": "^8.10.118", "@types/node": "^20.11.0", typescript: "^5.2.2" },
// //             },
// //             { spaces: 2 }
// //           );
// //         }

// //         // tsconfig.json
// //         const tsconfigPath = path.join(lambdasDir, lambdaName, "tsconfig.json");
// //         if (!fs.existsSync(tsconfigPath)) {
// //           fs.writeJsonSync(
// //             tsconfigPath,
// //             {
// //               compilerOptions: {
// //                 target: "ES2021",
// //                 module: "CommonJS",
// //                 outDir: "dist",
// //                 rootDir: "src",
// //                 strict: true,
// //                 esModuleInterop: true,
// //                 forceConsistentCasingInFileNames: true,
// //               },
// //               include: ["src/**/*"],
// //             },
// //             { spaces: 2 }
// //           );
// //         }
// //       }
// //     }
// //   }

// //   console.log("\n✅ Bot created successfully under packages folder!");
// // })();