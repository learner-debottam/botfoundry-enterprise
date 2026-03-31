import inquirer from "inquirer";

export async function promptUser() {
  return inquirer.prompt([
    {
      type: "input",
      name: "botName",
      message: "Enter bot name:",
      validate: (input: string) =>
        input ? true : "Bot name cannot be empty"
    },
    {
      type: "list",
      name: "type",
      message: "Select bot type:",
      choices: ["with-lambda", "without-lambda"]
    }
  ]);
}