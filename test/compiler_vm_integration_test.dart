import 'package:flexx/src/compiler/compiler.dart';
import 'package:flexx/src/lexer/lexer.dart';
import 'package:flexx/src/parser/parser.dart';
import 'package:flexx/src/vm/virtual_machine.dart';
import 'package:test/test.dart';

void main() {
  group('Compiler and VM integration', () {
    test('executes Flexx source through the complete pipeline', () {
      const source = '''
Flexx {
  let total = 0;
  let counter = 1;

  while (counter <= 5) {
    total = total + counter;
    counter = counter + 1;
  }

  if (total == 15) {
    print "Total: " + total;
  } else {
    print "Unexpected result";
  }
}
''';

      final output = <Object?>[];
      final tokens = Lexer(source).scanTokens();
      final program = Parser(tokens).parse();
      final bytecode = Compiler().compile(program);

      VirtualMachine(onPrint: output.add).run(bytecode);

      expect(output, ['Total: 15.0']);
    });

    test('executes arithmetic and built-in PI from source', () {
      const source = '''
Flexx {
  let radius = 2;
  print PI * radius * radius;
}
''';

      final output = <Object?>[];
      final program = Parser(Lexer(source).scanTokens()).parse();
      final bytecode = Compiler().compile(program);

      VirtualMachine(onPrint: output.add).run(bytecode);

      expect(output, [12.566370614359172]);
    });
  });
}
