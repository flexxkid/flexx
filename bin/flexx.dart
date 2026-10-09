import 'package:flexx/src/interpreter/interpreter.dart';
import 'package:flexx/src/lexer/lexer.dart';
import 'package:flexx/src/parser/parser.dart';
import 'package:flexx/src/runtime/environment.dart';

void main() {
  const source = '''
Flexx {
  print true && false;
  print true || false;
  print !true;
  print !false;
  print (10 > 5) && (7 == 7);
}
''';

  final lexer = Lexer(source);
  final tokens = lexer.scanTokens();

  final parser = Parser(tokens);
  final program = parser.parse();

  final environment = Environment();
  final interpreter = Interpreter(environment);

  interpreter.interpret(program);
}