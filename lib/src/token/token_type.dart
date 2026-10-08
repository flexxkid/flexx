enum TokenType {
  // Language keywords
  flexx,
  print,
  let,

  // Literals
  identifier,
  number,
  string,

  // Arithmetic operators
  plus,
  minus,
  multiply,
  divide,
  modulo,

  // Comparison operators
  equal,
  notEqual,
  greater,
  greaterEqual,
  less,
  lessEqual,

  // Logical operators
  not,
  and,
  or,

  // Assignment
  assign,

  // Delimiters
  semicolon,
  comma,
  dot,

  leftParen,
  rightParen,

  leftBrace,
  rightBrace,

  leftBracket,
  rightBracket,

  // Special
  eof,
}
