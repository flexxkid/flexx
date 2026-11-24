import 'opcode.dart';

class Instruction {
  final OpCode opcode;
  final Object? operand;

  const Instruction(this.opcode, [this.operand]);

  @override
  String toString() {
    if (operand == null) {
      return opcode.name.toUpperCase();
    }

    return '${opcode.name.toUpperCase()} $operand';
  }
}
