enum OpCode {
  // Constants
  constant,

  // Stack operations
  pop,
  duplicate,

  // Variables
  defineGlobal,
  getGlobal,
  setGlobal,

  // Arithmetic
  add,
  subtract,
  multiply,
  divide,
  modulo,
  negate,

  // Comparisons
  equal,
  notEqual,
  greater,
  greaterEqual,
  less,
  lessEqual,

  // Logical operations
  not,
  and,
  or,

  // Output
  print,

  // Control flow
  jump,
  jumpIfFalse,
  loop,

  // Scope management
  enterScope,
  exitScope,

  // Program termination
  halt,
}
