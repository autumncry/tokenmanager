#!/usr/bin/env node
import { spawnSync } from "node:child_process";
import { existsSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const root = dirname(dirname(fileURLToPath(import.meta.url)));
const releaseBinary = join(root, ".build", "release", "tokenmanagerctl");
const debugBinary = join(root, ".build", "debug", "tokenmanagerctl");
const args = process.argv.slice(2);

function run(cmd, commandArgs) {
  const result = spawnSync(cmd, commandArgs, { stdio: "inherit", cwd: root });
  if (result.status !== 0) process.exit(result.status ?? 1);
}

if (existsSync(releaseBinary)) {
  run(releaseBinary, args);
} else if (existsSync(debugBinary)) {
  run(debugBinary, args);
} else {
  run("swift", ["run", "tokenmanagerctl", ...args]);
}
