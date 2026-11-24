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
  group('Flexx while loops', () {
    test('repeats while the condition is true', () {
      expect(
        executeFlexx('''
Flexx {
  let count = 1;

  while (count <= 5) {
    print count;
    count = count + 1;
  }
}
'''),
        ['1.0', '2.0', '3.0', '4.0', '5.0'],
      );
    });

    test('does not execute when the condition is initially false', () {
      expect(
        executeFlexx('''
Flexx {
  let count = 10;

  while (count < 5) {
    print count;
    count = count + 1;
  }
}
'''),
        isEmpty,
      );
    });

    test('re-evaluates the condition after each iteration', () {
      expect(
        executeFlexx('''
Flexx {
  let count = 1;

  while (count < 4) {
    count = count + 1;
  }

  print count;
}
'''),
        ['4.0'],
      );
    });

    test('updates variables from enclosing scopes', () {
      expect(
        executeFlexx('''
Flexx {
  let total = 0;
  let count = 1;

  while (count <= 3) {
    total = total + count;
    count = count + 1;
  }

  print total;
}
'''),
        ['6.0'],
      );
    });

    test('supports nested while loops', () {
      expect(
        executeFlexx('''
Flexx {
  let outer = 1;

  while (outer <= 2) {
    let inner = 1;

    while (inner <= 2) {
      print outer * 10 + inner;
      inner = inner + 1;
    }

    outer = outer + 1;
  }
}
'''),
        ['11.0', '12.0', '21.0', '22.0'],
      );
    });

    test('keeps loop-body variables scoped to the loop body', () {
      expect(
        () => executeFlexx('''
Flexx {
  let count = 0;

  while (count < 1) {
    let temporary = 100;
    count = count + 1;
  }

  print temporary;
}
'''),
        throwsA(isA<Exception>()),
      );
    });
  });
}
