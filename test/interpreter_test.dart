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
      final lexer = Lexer(source);
      final tokens = lexer.scanTokens();

      final parser = Parser(tokens);
      final program = parser.parse();

      final interpreter = Interpreter(Environment());
      interpreter.interpret(program);
    },
    zoneSpecification: ZoneSpecification(
      print: (self, parent, zone, line) {
        output.add(line);
      },
    ),
  );

  return output;
}

void main() {
  group('Flexx conditional statements', () {
    test('executes if branch when condition is true', () {
      final output = executeFlexx('''
Flexx {
  if (true) {
    print "TRUE";
  }
}
''');

      expect(output, ['TRUE']);
    });

    test('skips if branch when condition is false', () {
      final output = executeFlexx('''
Flexx {
  if (false) {
    print "WRONG";
  }
  print "DONE";
}
''');

      expect(output, ['DONE']);
    });

    test('executes else branch when condition is false', () {
      final output = executeFlexx('''
Flexx {
  if (false) {
    print "WRONG";
  } else {
    print "ELSE";
  }
}
''');

      expect(output, ['ELSE']);
    });

    test('executes only the selected branch', () {
      final output = executeFlexx('''
Flexx {
  if (true) {
    print "FIRST";
  } else {
    print "SECOND";
  }
}
''');

      expect(output, ['FIRST']);
    });

    test('supports nested if statements', () {
      final output = executeFlexx('''
Flexx {
  if (true) {
    if (false) {
      print "WRONG";
    } else {
      print "NESTED";
    }
  }
}
''');

      expect(output, ['NESTED']);
    });

    test('supports logical expressions in conditions', () {
      final output = executeFlexx('''
Flexx {
  if (10 > 5 && 7 == 7) {
    print "PASS";
  } else {
    print "FAIL";
  }
}
''');

      expect(output, ['PASS']);
    });
  });

  group('Flexx lexical scoping', () {
    test('allows access to variables from outer scopes', () {
      final output = executeFlexx('''
Flexx {
  let message = "outer";

  if (true) {
    print message;
  }

  print message;
}
''');

      expect(output, ['outer', 'outer']);
    });

    test('supports variable shadowing inside blocks', () {
      final output = executeFlexx('''
Flexx {
  let message = "outer";

  if (true) {
    let message = "inner";
    print message;
  }

  print message;
}
''');

      expect(output, ['inner', 'outer']);
    });

    test('does not expose block-local variables outside blocks', () {
      expect(
        () => executeFlexx('''
Flexx {
  if (true) {
    let secret = "hidden";
  }

  print secret;
}
'''),
        throwsA(isA<Exception>()),
      );
    });

    test('restores the enclosing environment after nested blocks', () {
      final output = executeFlexx('''
Flexx {
  let value = "global";

  if (true) {
    let value = "local";

    if (true) {
      print value;
    }
  }

  print value;
}
''');

      expect(output, ['local', 'global']);
    });
  });
}
