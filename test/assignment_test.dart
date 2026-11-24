import 'dart:async';

import 'package:flexx/src/interpreter/interpreter.dart';
import 'package:flexx/src/lexer/lexer.dart';
import 'package:flexx/src/parser/parser.dart';
import 'package:flexx/src/runtime/environment.dart';
import 'package:test/test.dart';

List<String> executeFlexx(String source) {
  final output = <String>[];

  runZoned<void>(
    () {
      final tokens = Lexer(source).scanTokens();
      final program = Parser(tokens).parse();

      Interpreter(Environment()).interpret(program);
    },
    zoneSpecification: ZoneSpecification(
      print: (self, parent, zone, line) => output.add(line),
    ),
  );

  return output;
}

void main() {
  group('Flexx variable assignment', () {
    test('reassigns an existing variable', () {
      expect(
        executeFlexx('''
Flexx {
  let count = 1;
  count = 5;
  print count;
}
'''),
        ['5.0'],
      );
    });

    test('supports arithmetic during reassignment', () {
      expect(
        executeFlexx('''
Flexx {
  let count = 5;
  count = count + 3;
  print count;
}
'''),
        ['8.0'],
      );
    });

    test('updates variables from enclosing scopes', () {
      expect(
        executeFlexx('''
Flexx {
  let count = 1;

  if (true) {
    count = 10;
  }

  print count;
}
'''),
        ['10.0'],
      );
    });

    test('preserves block variable shadowing', () {
      expect(
        executeFlexx('''
Flexx {
  let count = 1;

  if (true) {
    let count = 5;
    count = 8;
    print count;
  }

  print count;
}
'''),
        ['8.0', '1.0'],
      );
    });

    test('supports chained assignment', () {
      expect(
        executeFlexx('''
Flexx {
  let a = 0;
  let b = 0;

  a = b = 10;

  print a;
  print b;
}
'''),
        ['10.0', '10.0'],
      );
    });

    test('rejects assignment to undefined variables', () {
      expect(
        () => executeFlexx('''
Flexx {
  missing = 10;
}
'''),
        throwsA(isA<Exception>()),
      );
    });

    test('rejects invalid assignment targets', () {
      expect(
        () => executeFlexx('''
Flexx {
  (10 + 5) = 20;
}
'''),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
