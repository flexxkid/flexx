import 'package:flexx/src/compiler/bytecode.dart';
import 'package:flexx/src/compiler/instruction.dart';
import 'package:flexx/src/compiler/opcode.dart';
import 'package:flexx/src/vm/virtual_machine.dart';
import 'package:test/test.dart';

void main() {
  group('Virtual Machine Scopes', () {
    test('creates and exits a scope', () {
      final vm = VirtualMachine();

      vm.run(
        Bytecode(
          constants: [],
          instructions: [
            Instruction(OpCode.enterScope),
            Instruction(OpCode.exitScope),
            Instruction(OpCode.halt),
          ],
        ),
      );

      expect(vm.stack, isEmpty);
    });

    test('accesses global variables from a child scope', () {
      final vm = VirtualMachine();

      vm.run(
        Bytecode(
          constants: [10.0],
          instructions: [
            Instruction(OpCode.constant, 0),
            Instruction(OpCode.defineGlobal, 'score'),
            Instruction(OpCode.enterScope),
            Instruction(OpCode.getGlobal, 'score'),
            Instruction(OpCode.exitScope),
            Instruction(OpCode.halt),
          ],
        ),
      );

      expect(vm.stack, [10.0]);
    });

    test('updates a global variable from a child scope', () {
      final vm = VirtualMachine();

      vm.run(
        Bytecode(
          constants: [10.0, 25.0],
          instructions: [
            Instruction(OpCode.constant, 0),
            Instruction(OpCode.defineGlobal, 'score'),
            Instruction(OpCode.enterScope),
            Instruction(OpCode.constant, 1),
            Instruction(OpCode.duplicate),
            Instruction(OpCode.setGlobal, 'score'),
            Instruction(OpCode.pop),
            Instruction(OpCode.exitScope),
            Instruction(OpCode.halt),
          ],
        ),
      );

      expect(vm.environment.get('score'), 25.0);
      expect(vm.stack, isEmpty);
    });

    test('supports variable shadowing', () {
      final vm = VirtualMachine();

      vm.run(
        Bytecode(
          constants: [10.0, 20.0],
          instructions: [
            Instruction(OpCode.constant, 0),
            Instruction(OpCode.defineGlobal, 'score'),
            Instruction(OpCode.enterScope),
            Instruction(OpCode.constant, 1),
            Instruction(OpCode.defineGlobal, 'score'),
            Instruction(OpCode.getGlobal, 'score'),
            Instruction(OpCode.exitScope),
            Instruction(OpCode.getGlobal, 'score'),
            Instruction(OpCode.halt),
          ],
        ),
      );

      expect(vm.stack, [20.0, 10.0]);
      expect(vm.environment.get('score'), 10.0);
    });

    test('supports nested scope lookup', () {
      final vm = VirtualMachine();

      vm.run(
        Bytecode(
          constants: [42.0],
          instructions: [
            Instruction(OpCode.enterScope),
            Instruction(OpCode.constant, 0),
            Instruction(OpCode.defineGlobal, 'answer'),
            Instruction(OpCode.enterScope),
            Instruction(OpCode.getGlobal, 'answer'),
            Instruction(OpCode.exitScope),
            Instruction(OpCode.exitScope),
            Instruction(OpCode.halt),
          ],
        ),
      );

      expect(vm.stack, [42.0]);
    });

    test('rejects access to a local variable after scope exit', () {
      final vm = VirtualMachine();

      expect(
        () => vm.run(
          Bytecode(
            constants: [42.0],
            instructions: [
              Instruction(OpCode.enterScope),
              Instruction(OpCode.constant, 0),
              Instruction(OpCode.defineGlobal, 'localValue'),
              Instruction(OpCode.exitScope),
              Instruction(OpCode.getGlobal, 'localValue'),
              Instruction(OpCode.halt),
            ],
          ),
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('makes PI available inside nested scopes', () {
      final vm = VirtualMachine();

      vm.run(
        Bytecode(
          constants: [],
          instructions: [
            Instruction(OpCode.enterScope),
            Instruction(OpCode.enterScope),
            Instruction(OpCode.getGlobal, 'PI'),
            Instruction(OpCode.exitScope),
            Instruction(OpCode.exitScope),
            Instruction(OpCode.halt),
          ],
        ),
      );

      expect(vm.stack, [3.141592653589793]);
    });

    test('rejects exiting the global scope', () {
      final vm = VirtualMachine();

      expect(
        () => vm.run(
          Bytecode(
            constants: [],
            instructions: [
              Instruction(OpCode.exitScope),
              Instruction(OpCode.halt),
            ],
          ),
        ),
        throwsA(isA<StateError>()),
      );
    });
  });
}
