const { greet, farewell } = require("../src/index");

describe("greet", () => {
  it("returns a greeting with the given name", () => {
    expect(greet("World")).toBe("Hello, World!");
  });

  it("throws when name is empty", () => {
    expect(() => greet("")).toThrow("Name must be a non-empty string");
  });

  it("throws when name is not a string", () => {
    expect(() => greet(42)).toThrow("Name must be a non-empty string");
  });
});

describe("farewell", () => {
  it("returns a farewell with the given name", () => {
    expect(farewell("World")).toBe("Goodbye, World!");
  });

  it("throws when name is empty", () => {
    expect(() => farewell("")).toThrow("Name must be a non-empty string");
  });
});
