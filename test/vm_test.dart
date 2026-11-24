import 'package:flexx/src/compiler/bytecode.dart';
import 'package:flexx/src/compiler/instruction.dart';
import 'package:flexx/src/compiler/opcode.dart';
import 'package:flexx/src/vm/virtual_machine.dart';
import 'package:test/test.dart';

void main() {
  VirtualMachine execute(
    List<Object?> constants,
    List<Instruction> instructions, {
    void Function(Object?)? onPrint,
  }) {
    final vm = VirtualMachine(onPrint: onPrint);

    vm.run(
      Bytecode(
        constants: constants,
        instructions: [...instructions, Instruction(OpCode.halt)],
      ),
    );

    return vm;
  }

  group('Flexx Virtual Machine', () {
    test('loads a constant onto the stack', () {
      final bytecode = Bytecode(
        constants: [42.0],
        instructions: [
          Instruction(OpCode.constant, 0),
          Instruction(OpCode.halt),
        ],
      );

      final vm = VirtualMachine();
      vm.run(bytecode);

      expect(vm.stack, [42.0]);
    });

    test('supports multiple constants', () {
      final bytecode = Bytecode(
        constants: [10.0, 20.0, 'Flexx'],
        instructions: [
          Instruction(OpCode.constant, 0),
          Instruction(OpCode.constant, 1),
          Instruction(OpCode.constant, 2),
          Instruction(OpCode.halt),
        ],
      );

      final vm = VirtualMachine();
      vm.run(bytecode);

      expect(vm.stack, [10.0, 20.0, 'Flexx']);
    });

    test('removes the top stack value with POP', () {
      final bytecode = Bytecode(
        constants: [10.0, 20.0],
        instructions: [
          Instruction(OpCode.constant, 0),
          Instruction(OpCode.constant, 1),
          Instruction(OpCode.pop),
          Instruction(OpCode.halt),
        ],
      );

      final vm = VirtualMachine();
      vm.run(bytecode);

      expect(vm.stack, [10.0]);
    });

    test('duplicates the top stack value', () {
      final bytecode = Bytecode(
        constants: [42.0],
        instructions: [
          Instruction(OpCode.constant, 0),
          Instruction(OpCode.duplicate),
          Instruction(OpCode.halt),
        ],
      );

      final vm = VirtualMachine();
      vm.run(bytecode);

      expect(vm.stack, [42.0, 42.0]);
    });

    test('HALT stops execution', () {
      final bytecode = Bytecode(
        constants: [10.0, 20.0],
        instructions: [
          Instruction(OpCode.constant, 0),
          Instruction(OpCode.halt),
          Instruction(OpCode.constant, 1),
        ],
      );

      final vm = VirtualMachine();
      vm.run(bytecode);

      expect(vm.stack, [10.0]);
    });

    test('throws an error on stack underflow', () {
      final bytecode = Bytecode(
        constants: [],
        instructions: [Instruction(OpCode.pop), Instruction(OpCode.halt)],
      );

      final vm = VirtualMachine();

      expect(() => vm.run(bytecode), throwsA(isA<StateError>()));
    });

    test('throws an error for an invalid constant index', () {
      final bytecode = Bytecode(
        constants: [42.0],
        instructions: [
          Instruction(OpCode.constant, 5),
          Instruction(OpCode.halt),
        ],
      );

      final vm = VirtualMachine();

      expect(() => vm.run(bytecode), throwsA(isA<StateError>()));
    });

    test('resets the stack when executing another program', () {
      final vm = VirtualMachine();

      vm.run(
        Bytecode(
          constants: [10.0],
          instructions: [
            Instruction(OpCode.constant, 0),
            Instruction(OpCode.halt),
          ],
        ),
      );

      vm.run(
        Bytecode(
          constants: [20.0],
          instructions: [
            Instruction(OpCode.constant, 0),
            Instruction(OpCode.halt),
          ],
        ),
      );

      expect(vm.stack, [20.0]);
    });

    test('defines and retrieves global variables', () {
      final bytecode = Bytecode(
        constants: [100.0],
        instructions: [
          Instruction(OpCode.constant, 0),
          Instruction(OpCode.defineGlobal, 'score'),
          Instruction(OpCode.getGlobal, 'score'),
          Instruction(OpCode.halt),
        ],
      );

      final vm = VirtualMachine();
      vm.run(bytecode);

      expect(vm.stack, [100.0]);
      expect(vm.environment.get('score'), 100.0);
    });

    test('updates an existing global variable', () {
      final bytecode = Bytecode(
        constants: [10.0, 25.0],
        instructions: [
          Instruction(OpCode.constant, 0),
          Instruction(OpCode.defineGlobal, 'score'),
          Instruction(OpCode.constant, 1),
          Instruction(OpCode.duplicate),
          Instruction(OpCode.setGlobal, 'score'),
          Instruction(OpCode.pop),
          Instruction(OpCode.halt),
        ],
      );

      final vm = VirtualMachine();
      vm.run(bytecode);

      expect(vm.stack, isEmpty);
      expect(vm.environment.get('score'), 25.0);
    });

    test('preserves the built-in PI constant', () {
      final bytecode = Bytecode(
        constants: [],
        instructions: [
          Instruction(OpCode.getGlobal, 'PI'),
          Instruction(OpCode.halt),
        ],
      );

      final vm = VirtualMachine();
      vm.run(bytecode);

      expect(vm.stack.single, closeTo(3.141592653589793, 0.0000001));
    });

    test('throws an error when retrieving an undefined variable', () {
      final bytecode = Bytecode(
        constants: [],
        instructions: [
          Instruction(OpCode.getGlobal, 'missing'),
          Instruction(OpCode.halt),
        ],
      );

      final vm = VirtualMachine();

      expect(() => vm.run(bytecode), throwsA(isA<Exception>()));
    });

    test('throws an error when assigning an undefined variable', () {
      final bytecode = Bytecode(
        constants: [50.0],
        instructions: [
          Instruction(OpCode.constant, 0),
          Instruction(OpCode.setGlobal, 'missing'),
          Instruction(OpCode.halt),
        ],
      );

      final vm = VirtualMachine();

      expect(() => vm.run(bytecode), throwsA(isA<Exception>()));
    });

    group('Arithmetic operations', () {
      test('adds numbers', () {
        final vm = execute(
          [10.0, 5.0],
          [
            Instruction(OpCode.constant, 0),
            Instruction(OpCode.constant, 1),
            Instruction(OpCode.add),
          ],
        );

        expect(vm.stack, [15.0]);
      });

      test('concatenates strings', () {
        final vm = execute(
          ['Flexx', ' Language'],
          [
            Instruction(OpCode.constant, 0),
            Instruction(OpCode.constant, 1),
            Instruction(OpCode.add),
          ],
        );

        expect(vm.stack, ['Flexx Language']);
      });

      test('subtracts numbers', () {
        final vm = execute(
          [10.0, 4.0],
          [
            Instruction(OpCode.constant, 0),
            Instruction(OpCode.constant, 1),
            Instruction(OpCode.subtract),
          ],
        );

        expect(vm.stack, [6.0]);
      });

      test('multiplies numbers', () {
        final vm = execute(
          [6.0, 7.0],
          [
            Instruction(OpCode.constant, 0),
            Instruction(OpCode.constant, 1),
            Instruction(OpCode.multiply),
          ],
        );

        expect(vm.stack, [42.0]);
      });

      test('divides numbers', () {
        final vm = execute(
          [20.0, 4.0],
          [
            Instruction(OpCode.constant, 0),
            Instruction(OpCode.constant, 1),
            Instruction(OpCode.divide),
          ],
        );

        expect(vm.stack, [5.0]);
      });

      test('calculates modulo', () {
        final vm = execute(
          [10.0, 3.0],
          [
            Instruction(OpCode.constant, 0),
            Instruction(OpCode.constant, 1),
            Instruction(OpCode.modulo),
          ],
        );

        expect(vm.stack, [1.0]);
      });

      test('negates a number', () {
        final vm = execute(
          [15.0],
          [Instruction(OpCode.constant, 0), Instruction(OpCode.negate)],
        );

        expect(vm.stack, [-15.0]);
      });

      test('rejects non-numeric arithmetic operands', () {
        expect(
          () => execute(
            ['hello', 5.0],
            [
              Instruction(OpCode.constant, 0),
              Instruction(OpCode.constant, 1),
              Instruction(OpCode.subtract),
            ],
          ),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('Comparison operations', () {
      test('checks equality', () {
        final vm = execute(
          [10.0, 10.0],
          [
            Instruction(OpCode.constant, 0),
            Instruction(OpCode.constant, 1),
            Instruction(OpCode.equal),
          ],
        );

        expect(vm.stack, [true]);
      });

      test('checks inequality', () {
        final vm = execute(
          [10.0, 5.0],
          [
            Instruction(OpCode.constant, 0),
            Instruction(OpCode.constant, 1),
            Instruction(OpCode.notEqual),
          ],
        );

        expect(vm.stack, [true]);
      });

      test('checks greater than', () {
        final vm = execute(
          [10.0, 5.0],
          [
            Instruction(OpCode.constant, 0),
            Instruction(OpCode.constant, 1),
            Instruction(OpCode.greater),
          ],
        );

        expect(vm.stack, [true]);
      });

      test('checks greater than or equal', () {
        final vm = execute(
          [10.0, 10.0],
          [
            Instruction(OpCode.constant, 0),
            Instruction(OpCode.constant, 1),
            Instruction(OpCode.greaterEqual),
          ],
        );

        expect(vm.stack, [true]);
      });

      test('checks less than', () {
        final vm = execute(
          [5.0, 10.0],
          [
            Instruction(OpCode.constant, 0),
            Instruction(OpCode.constant, 1),
            Instruction(OpCode.less),
          ],
        );

        expect(vm.stack, [true]);
      });

      test('checks less than or equal', () {
        final vm = execute(
          [10.0, 10.0],
          [
            Instruction(OpCode.constant, 0),
            Instruction(OpCode.constant, 1),
            Instruction(OpCode.lessEqual),
          ],
        );

        expect(vm.stack, [true]);
      });
    });

    group('Logical operations', () {
      test('NOT negates true', () {
        final vm = execute(
          [true],
          [Instruction(OpCode.constant, 0), Instruction(OpCode.not)],
        );

        expect(vm.stack, [false]);
      });

      test('NOT negates false', () {
        final vm = execute(
          [false],
          [Instruction(OpCode.constant, 0), Instruction(OpCode.not)],
        );

        expect(vm.stack, [true]);
      });

      test('NOT treats null as falsey', () {
        final vm = execute(
          [null],
          [Instruction(OpCode.constant, 0), Instruction(OpCode.not)],
        );

        expect(vm.stack, [true]);
      });

      test('NOT treats other values as truthy', () {
        final vm = execute(
          ['Flexx'],
          [Instruction(OpCode.constant, 0), Instruction(OpCode.not)],
        );

        expect(vm.stack, [false]);
      });
    });

    group('Output operations', () {
      test('PRINT sends values to the output callback', () {
        final output = <Object?>[];

        final vm = execute(
          ['Hello from Flexx', 42.0],
          [
            Instruction(OpCode.constant, 0),
            Instruction(OpCode.print),
            Instruction(OpCode.constant, 1),
            Instruction(OpCode.print),
          ],
          onPrint: output.add,
        );

        expect(output, ['Hello from Flexx', 42.0]);
        expect(vm.stack, isEmpty);
      });
    });
  });
}
