/**
 * A simple greeter module.
 * This file exists so the hookflows have real source code to govern.
 */

function greet(name) {
  if (!name || typeof name !== "string") {
    throw new Error("Name must be a non-empty string");
  }
  return `Hello, ${name}!`;
}

function farewell(name) {
  if (!name || typeof name !== "string") {
    throw new Error("Name must be a non-empty string");
  }
  return `Goodbye, ${name}!`;
}

module.exports = { greet, farewell };
