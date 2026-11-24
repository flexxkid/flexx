import 'package:flexx/src/compiler/bytecode.dart';
import 'package:flexx/src/compiler/compiler.dart';
import 'package:flexx/src/compiler/opcode.dart';
import 'package:flexx/src/lexer/lexer.dart';
import 'package:flexx/src/parser/parser.dart';
import 'package:test/test.dart';

Bytecode compileSource(String source) {
  final tokens = Lexer(source).scanTokens();
  final program = Parser(tokens).parse();

  return Compiler().compile(program);
}

void main() {
  group('Flexx Compiler', () {
    test('compiles numeric constants and print statements', () {
      const source = '''
Flexx {
  print 42;
}
''';

      final bytecode = compileSource(source);

      expect(bytecode.constants, [42.0]);

      expect(bytecode.instructions.map((i) => i.opcode), [
        OpCode.constant,
        OpCode.print,
        OpCode.halt,
      ]);
    });

    test('compiles variable declarations and arithmetic', () {
      const source = '''
Flexx {
  let a = 10;
  let b = 20;
  let result = a + b;
  print result;
}
''';

      final bytecode = compileSource(source);

      expect(bytecode.constants, [10.0, 20.0]);

      expect(bytecode.instructions.map((i) => i.opcode), [
        OpCode.constant,
        OpCode.defineGlobal,
        OpCode.constant,
        OpCode.defineGlobal,
        OpCode.getGlobal,
        OpCode.getGlobal,
        OpCode.add,
        OpCode.defineGlobal,
        OpCode.getGlobal,
        OpCode.print,
        OpCode.halt,
      ]);
    });

    test('compiles variable reassignment', () {
      const source = '''
Flexx {
  let a = 10;
  a = a + 5;
  print a;
}
''';

      final bytecode = compileSource(source);

      expect(bytecode.instructions.map((i) => i.opcode), [
        OpCode.constant,
        OpCode.defineGlobal,
        OpCode.getGlobal,
        OpCode.constant,
        OpCode.add,
        OpCode.duplicate,
        OpCode.setGlobal,
        OpCode.pop,
        OpCode.getGlobal,
        OpCode.print,
        OpCode.halt,
      ]);
    });

    test('stores string and boolean constants', () {
      const source = '''
Flexx {
  print "Hello Flexx";
  print true;
  print false;
}
''';

      final bytecode = compileSource(source);

      expect(bytecode.constants, ['Hello Flexx', true, false]);
    });

    test('compiles comparison expressions', () {
      const source = '''
Flexx {
  print 10 > 5;
  print 10 == 10;
  print 5 != 3;
}
''';

      final bytecode = compileSource(source);

      expect(
        bytecode.instructions
            .where(
              (i) =>
                  i.opcode == OpCode.greater ||
                  i.opcode == OpCode.equal ||
                  i.opcode == OpCode.notEqual,
            )
            .map((i) => i.opcode),
        [OpCode.greater, OpCode.equal, OpCode.notEqual],
      );
    });

    test('compiles if/else statements with jumps and scopes', () {
      const source = '''
Flexx {
  if (true) {
    print 1;
  } else {
    print 2;
  }
}
''';

      final bytecode = compileSource(source);

      expect(bytecode.constants, [true, 1.0, 2.0]);

      expect(bytecode.instructions.map((i) => i.opcode), [
        OpCode.constant,
        OpCode.jumpIfFalse,
        OpCode.enterScope,
        OpCode.constant,
        OpCode.print,
        OpCode.exitScope,
        OpCode.jump,
        OpCode.enterScope,
        OpCode.constant,
        OpCode.print,
        OpCode.exitScope,
        OpCode.halt,
      ]);

      expect(bytecode.instructions[1].operand, 7);

      expect(bytecode.instructions[6].operand, 11);
    });

    test('compiles if statements without else branches', () {
      const source = '''
Flexx {
  if (true) {
    print 1;
  }
}
''';

      final bytecode = compileSource(source);

      expect(bytecode.instructions.map((i) => i.opcode), [
        OpCode.constant,
        OpCode.jumpIfFalse,
        OpCode.enterScope,
        OpCode.constant,
        OpCode.print,
        OpCode.exitScope,
        OpCode.halt,
      ]);

      expect(bytecode.instructions[1].operand, 6);
    });

    test('compiles while loops with backward jumps', () {
      const source = '''
Flexx {
  let count = 0;

  while (count < 3) {
    print count;
    count = count + 1;
  }
}
''';

      final bytecode = compileSource(source);
      final instructions = bytecode.instructions;

      expect(
        instructions.where((i) => i.opcode == OpCode.jumpIfFalse),
        hasLength(1),
      );

      final loopInstruction = instructions.lastWhere(
        (i) => i.opcode == OpCode.loop,
      );

      expect(loopInstruction.operand, 2);

      expect(instructions.any((i) => i.opcode == OpCode.enterScope), isTrue);
      expect(instructions.any((i) => i.opcode == OpCode.exitScope), isTrue);
    });

    test('compiles logical AND using short-circuit jumps', () {
      const source = '''
Flexx {
  print true && false;
}
''';

      final bytecode = compileSource(source);

      expect(bytecode.constants, [true, false, false]);

      expect(bytecode.instructions.map((i) => i.opcode), [
        OpCode.constant,
        OpCode.jumpIfFalse,
        OpCode.constant,
        OpCode.not,
        OpCode.not,
        OpCode.jump,
        OpCode.constant,
        OpCode.print,
        OpCode.halt,
      ]);

      expect(bytecode.instructions[1].operand, 6);
      expect(bytecode.instructions[5].operand, 7);
    });

    test('compiles logical OR using short-circuit jumps', () {
      const source = '''
Flexx {
  print false || true;
}
''';

      final bytecode = compileSource(source);

      expect(bytecode.constants, [false, true, true]);

      expect(bytecode.instructions.map((i) => i.opcode), [
        OpCode.constant,
        OpCode.jumpIfFalse,
        OpCode.constant,
        OpCode.jump,
        OpCode.constant,
        OpCode.not,
        OpCode.not,
        OpCode.print,
        OpCode.halt,
      ]);

      expect(bytecode.instructions[1].operand, 4);
      expect(bytecode.instructions[3].operand, 7);
    });

    test('compiles nested control-flow statements', () {
      const source = '''
Flexx {
  if (true) {
    while (false) {
      print 1;
    }
  } else {
    print 2;
  }
}
''';

      final bytecode = compileSource(source);

      final instructions = bytecode.instructions;

      expect(
        instructions.where((i) => i.opcode == OpCode.jumpIfFalse),
        hasLength(2),
      );

      expect(instructions.where((i) => i.opcode == OpCode.loop), hasLength(1));

      expect(
        instructions.where((i) => i.opcode == OpCode.enterScope),
        hasLength(3),
      );

      expect(
        instructions.where((i) => i.opcode == OpCode.exitScope),
        hasLength(3),
      );
    });
  });
}
