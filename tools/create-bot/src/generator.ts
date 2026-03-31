import path from "path";
import fs from "fs-extra";
import { copyAndReplace } from "./file-utils";

export async function generateBot(options: any) {
  const { botName, type } = options;

  // const rootDir = process.cwd();
  // const templateDir = path.join(rootDir, "templates", type);
  // const targetDir = path.join(rootDir, "packages", botName);

  const repoRoot = path.resolve(__dirname, "../../../");

  const templateDir = path.join(repoRoot, "templates", type);
  const targetDir = path.join(repoRoot, "packages", botName);

  if (await fs.pathExists(targetDir)) {
    throw new Error(`Package ${botName} already exists`);
  }

  await fs.copy(templateDir, targetDir);

  await copyAndReplace(targetDir, {
    BOT_NAME: botName,
    PACKAGE_NAME: botName
  });
}