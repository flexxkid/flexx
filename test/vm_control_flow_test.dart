import 'package:flexx/src/compiler/bytecode.dart';
import 'package:flexx/src/compiler/instruction.dart';
import 'package:flexx/src/compiler/opcode.dart';
import 'package:flexx/src/vm/virtual_machine.dart';
import 'package:test/test.dart';

void main() {
  group('Virtual Machine Control Flow', () {
    test('JUMP skips instructions', () {
      final vm = VirtualMachine();

      vm.run(
        Bytecode(
          constants: [10.0, 20.0],
          instructions: [
            Instruction(OpCode.constant, 0),
            Instruction(OpCode.jump, 3),
            Instruction(OpCode.constant, 1),
            Instruction(OpCode.halt),
          ],
        ),
      );

      expect(vm.stack, [10.0]);
    });

    test('JUMP_IF_FALSE jumps when condition is false', () {
      final vm = VirtualMachine();

      vm.run(
        Bytecode(
          constants: [false, 10.0, 20.0],
          instructions: [
            Instruction(OpCode.constant, 0),
            Instruction(OpCode.jumpIfFalse, 4),
            Instruction(OpCode.constant, 1),
            Instruction(OpCode.jump, 5),
            Instruction(OpCode.constant, 2),
            Instruction(OpCode.halt),
          ],
        ),
      );

      expect(vm.stack, [20.0]);
    });

    test('JUMP_IF_FALSE continues when condition is true', () {
      final vm = VirtualMachine();

      vm.run(
        Bytecode(
          constants: [true, 10.0, 20.0],
          instructions: [
            Instruction(OpCode.constant, 0),
            Instruction(OpCode.jumpIfFalse, 4),
            Instruction(OpCode.constant, 1),
            Instruction(OpCode.jump, 5),
            Instruction(OpCode.constant, 2),
            Instruction(OpCode.halt),
          ],
        ),
      );

      expect(vm.stack, [10.0]);
    });

    test('JUMP_IF_FALSE removes the condition from the stack', () {
      final vm = VirtualMachine();

      vm.run(
        Bytecode(
          constants: [false],
          instructions: [
            Instruction(OpCode.constant, 0),
            Instruction(OpCode.jumpIfFalse, 3),
            Instruction(OpCode.halt),
            Instruction(OpCode.halt),
          ],
        ),
      );

      expect(vm.stack, isEmpty);
    });

    test('LOOP jumps back to an earlier instruction', () {
      final output = <Object?>[];
      final vm = VirtualMachine(onPrint: output.add);

      vm.run(
        Bytecode(
          constants: [0.0, 1.0, 3.0],
          instructions: [
            Instruction(OpCode.constant, 0),
            Instruction(OpCode.defineGlobal, 'i'),
            Instruction(OpCode.getGlobal, 'i'),
            Instruction(OpCode.constant, 2),
            Instruction(OpCode.less),
            Instruction(OpCode.jumpIfFalse, 15),
            Instruction(OpCode.getGlobal, 'i'),
            Instruction(OpCode.print),
            Instruction(OpCode.getGlobal, 'i'),
            Instruction(OpCode.constant, 1),
            Instruction(OpCode.add),
            Instruction(OpCode.duplicate),
            Instruction(OpCode.setGlobal, 'i'),
            Instruction(OpCode.pop),
            Instruction(OpCode.loop, 2),
            Instruction(OpCode.halt),
          ],
        ),
      );

      expect(output, [0.0, 1.0, 2.0]);
      expect(vm.environment.get('i'), 3.0);
      expect(vm.stack, isEmpty);
    });

    test('rejects an invalid JUMP target', () {
      final vm = VirtualMachine();

      expect(
        () => vm.run(
          Bytecode(
            constants: [],
            instructions: [
              Instruction(OpCode.jump, 10),
              Instruction(OpCode.halt),
            ],
          ),
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('rejects an invalid LOOP target', () {
      final vm = VirtualMachine();

      expect(
        () => vm.run(
          Bytecode(
            constants: [],
            instructions: [
              Instruction(OpCode.loop, -1),
              Instruction(OpCode.halt),
            ],
          ),
        ),
        throwsA(isA<StateError>()),
      );
    });
  });
}
