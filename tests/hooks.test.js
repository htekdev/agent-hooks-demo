const fs = require("fs");
const path = require("path");

const repoRoot = path.resolve(__dirname, "..");
const hookConfigDir = path.join(repoRoot, ".github", "hooks");
const scriptsDir = path.join(repoRoot, "scripts", "hooks");

const configFiles = [
  {
    name: "hooks.json",
    relativePath: path.join(".github", "hooks", "hooks.json"),
    absolutePath: path.join(hookConfigDir, "hooks.json"),
  },
  {
    name: "hooks-jetbrains.json",
    relativePath: path.join(".github", "hooks", "hooks-jetbrains.json"),
    absolutePath: path.join(hookConfigDir, "hooks-jetbrains.json"),
  },
  {
    name: "personal-hooks.json",
    relativePath: path.join("docs", "examples", "personal-hooks.json"),
    absolutePath: path.join(repoRoot, "docs", "examples", "personal-hooks.json"),
  },
];

const localHookConfigs = configFiles.filter(({ name }) => name !== "personal-hooks.json");
const jetBrainsAllowedEvents = new Set([
  "userPromptSubmitted",
  "preToolUse",
  "postToolUse",
  "errorOccurred",
]);

function readJsonFile(filePath) {
  return fs.readFileSync(filePath, "utf8");
}

function parseJsonFile(filePath) {
  return JSON.parse(readJsonFile(filePath));
}

function isObject(value) {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}

function getHookEntries(config) {
  return Object.entries(config.hooks).flatMap(([eventName, entries]) =>
    entries.map((entry, index) => ({ eventName, entry, index }))
  );
}

function getTimeout(entry) {
  return entry.timeoutSec ?? entry.timeout;
}

function getScriptPaths(config) {
  return getHookEntries(config).flatMap(({ entry }) =>
    [entry.bash, entry.powershell].filter(
      (scriptPath) => typeof scriptPath === "string" && scriptPath.trim().length > 0
    )
  );
}

describe("Hook Configuration Validation", () => {
  describe.each(configFiles)("$name", ({ absolutePath }) => {
    let raw;
    let config;

    beforeAll(() => {
      raw = readJsonFile(absolutePath);
      config = JSON.parse(raw);
    });

    it("parses as valid JSON", () => {
      expect(() => JSON.parse(raw)).not.toThrow();
    });

    it("has version 1", () => {
      expect(config.version).toBe(1);
    });

    it("has a hooks object", () => {
      expect(isObject(config.hooks)).toBe(true);
    });
  });
});

describe("Hook Configuration Schema Validation", () => {
  describe.each(configFiles)("$name", ({ absolutePath }) => {
    let config;

    beforeAll(() => {
      config = parseJsonFile(absolutePath);
    });

    it("uses version 1", () => {
      expect(config.version).toBe(1);
    });

    it("stores each hook event as an array", () => {
      expect(isObject(config.hooks)).toBe(true);

      Object.entries(config.hooks).forEach(([eventName, entries]) => {
        expect(Array.isArray(entries)).toBe(true);
        expect(eventName).toEqual(expect.any(String));
      });
    });

    it("defines command hook entries with at least one executable field", () => {
      getHookEntries(config).forEach(({ entry }) => {
        expect(isObject(entry)).toBe(true);
        expect(entry.type).toBe("command");
        expect(
          [entry.bash, entry.powershell, entry.command].some(
            (value) => typeof value === "string" && value.trim().length > 0
          )
        ).toBe(true);
      });
    });

    it("defines a positive timeout for every hook entry", () => {
      getHookEntries(config).forEach(({ entry }) => {
        const timeout = getTimeout(entry);
        expect(Number.isFinite(timeout)).toBe(true);
        expect(timeout).toBeGreaterThan(0);
      });
    });
  });
});

describe("Script Existence Checks", () => {
  describe.each(localHookConfigs)("$name", ({ absolutePath }) => {
    it("references existing bash and powershell scripts", () => {
      const config = parseJsonFile(absolutePath);
      const missingScripts = getScriptPaths(config).filter((scriptPath) => {
        const resolvedPath = path.resolve(__dirname, "..", scriptPath);
        return !fs.existsSync(resolvedPath);
      });

      expect(missingScripts).toEqual([]);
    });
  });
});

describe("JetBrains Event Subset Validation", () => {
  let config;

  beforeAll(() => {
    config = parseJsonFile(path.join(hookConfigDir, "hooks-jetbrains.json"));
  });

  it("only uses JetBrains-supported hook events", () => {
    const unsupportedEvents = Object.keys(config.hooks).filter(
      (eventName) => !jetBrainsAllowedEvents.has(eventName)
    );

    expect(unsupportedEvents).toEqual([]);
  });

  it("does not include unsupported session lifecycle events", () => {
    expect(Object.keys(config.hooks)).not.toContain("sessionStart");
    expect(Object.keys(config.hooks)).not.toContain("sessionEnd");
  });
});

const shellScripts = fs.existsSync(scriptsDir)
  ? fs.readdirSync(scriptsDir).filter((fileName) => fileName.endsWith(".sh"))
  : [];

(shellScripts.length > 0 ? describe : describe.skip)("Hook Script Syntax", () => {
  shellScripts.forEach((fileName) => {
    it(`${fileName} starts with a bash shebang`, () => {
      const scriptPath = path.join(scriptsDir, fileName);
      const [firstLine = ""] = readJsonFile(scriptPath).split(/\r?\n/, 1);

      expect(firstLine).toBe("#!/bin/bash");
    });
  });
});
