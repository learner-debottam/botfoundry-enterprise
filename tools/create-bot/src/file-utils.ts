import fs from "fs-extra";
import path from "path";

export async function copyAndReplace(
  dir: string,
  variables: Record<string, string>
) {
  const files = await getAllFiles(dir);

  for (const file of files) {
    let content = await fs.readFile(file, "utf-8");

    for (const [key, value] of Object.entries(variables)) {
      const regex = new RegExp(`{{${key}}}`, "g");
      content = content.replace(regex, value);
    }

    await fs.writeFile(file, content);
  }
}

async function getAllFiles(dir: string): Promise<string[]> {
  const entries = await fs.readdir(dir);
  const files = await Promise.all(
    entries.map(async (entry) => {
      const fullPath = path.join(dir, entry);
      const stat = await fs.stat(fullPath);

      return stat.isDirectory()
        ? getAllFiles(fullPath)
        : [fullPath];
    })
  );

  return files.flat();
}