#!/usr/bin/env node
import { spawnSync } from "node:child_process";
import { existsSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const root = dirname(dirname(fileURLToPath(import.meta.url)));
const script = join(root, "script", "package_app.sh");
const app = join(root, "dist", "TokenManager.app");
const command = process.argv[2] ?? "launch";

function run(cmd, args, options = {}) {
  const result = spawnSync(cmd, args, { stdio: "inherit", cwd: root, ...options });
  if (result.status !== 0) process.exit(result.status ?? 1);
}

switch (command) {
  case "build":
    run(script, []);
    break;
  case "install-app":
    run(script, []);
    run("osascript", [
      "-e",
      `do shell script "ditto '${app.replaceAll("'", "'\\''")}' '/Applications/TokenManager.app'" with administrator privileges`
    ]);
    break;
  case "launch":
  default:
    if (!existsSync(app)) run(script, []);
    run("open", ["-n", app]);
    break;
}
