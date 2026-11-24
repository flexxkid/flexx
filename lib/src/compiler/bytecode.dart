import 'instruction.dart';

class Bytecode {
  final List<Instruction> instructions;
  final List<Object?> constants;

  const Bytecode({required this.instructions, required this.constants});

  void disassemble() {
    print('===== FLEXX BYTECODE =====');

    for (var i = 0; i < instructions.length; i++) {
      final offset = i.toString().padLeft(4, '0');

      print('$offset  ${instructions[i]}');
    }

    print('\n===== CONSTANT POOL =====');

    for (var i = 0; i < constants.length; i++) {
      print('$i: ${constants[i]}');
    }

    print('=========================');
  }
}
