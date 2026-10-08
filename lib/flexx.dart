import 'package:flexx/src/ast/statement.dart';
import 'package:flexx/src/lexer/lexer.dart';
import 'package:flexx/src/parser/parser.dart';

void main() {
  const source = 'let radius = 7;';

  final lexer = Lexer(source);
  final tokens = lexer.scanTokens();

  final parser = Parser(tokens);
  final statements = parser.parse();

  final statement = statements.first;

  if (statement is VariableDeclaration) {
    print('Variable: ${statement.name.lexeme}');
    print('Value: ${(statement.initializer as dynamic).value}');
  }
}