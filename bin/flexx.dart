import 'package:flexx/src/ast/statement.dart';
import 'package:flexx/src/lexer/lexer.dart';
import 'package:flexx/src/parser/parser.dart';

void main() {
  const source = '''
Flexx {
  let radius = 7;
  print radius;
}
''';

  final lexer = Lexer(source);
  final tokens = lexer.scanTokens();

  final parser = Parser(tokens);
  final program = parser.parse();

  print('Program parsed successfully.');
  print('Statements: ${program.statements.length}');

  for (final statement in program.statements) {
    print('Statement: ${statement.runtimeType}');
  }
}
