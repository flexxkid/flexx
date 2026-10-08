import 'token_type.dart';

class Token {
  final TokenType type;
  final String lexeme;
  final Object? literal;
  final int line;
  final int column;

  const Token({
    required this.type,
    required this.lexeme,
    this.literal,
    required this.line,
    required this.column,
  });

  @override
  String toString() {
    return 'Token('
        'type: $type, '
        'lexeme: "$lexeme", '
        'literal: $literal, '
        'line: $line, '
        'column: $column'
        ')';
  }
}
