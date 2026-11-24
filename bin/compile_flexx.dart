import 'package:flexx/src/compiler/compiler.dart';
import 'package:flexx/src/lexer/lexer.dart';
import 'package:flexx/src/parser/parser.dart';

void main() {
  const source = '''
Flexx {
  let a = 10;
  let b = 20;
  let result = a + b;
  print result;
}
''';

  final tokens = Lexer(source).scanTokens();
  final program = Parser(tokens).parse();
  final bytecode = Compiler().compile(program);

  bytecode.disassemble();
}
