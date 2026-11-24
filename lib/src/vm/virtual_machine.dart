import '../compiler/bytecode.dart';
import '../compiler/opcode.dart';
import '../runtime/environment.dart';

class VirtualMachine {
  final Environment environment;
  final void Function(Object?) onPrint;

  final List<Object?> _stack = [];
  late Environment _currentEnvironment;

  int _instructionPointer = 0;
  bool _halted = false;

  VirtualMachine({Environment? environment, void Function(Object?)? onPrint})
    : environment = environment ?? Environment(),
      onPrint = onPrint ?? print {
    _currentEnvironment = this.environment;
  }

  List<Object?> get stack => List.unmodifiable(_stack);

  void run(Bytecode bytecode) {
    _stack.clear();
    _instructionPointer = 0;
    _halted = false;
    _currentEnvironment = environment;

    while (!_halted) {
      if (_instructionPointer >= bytecode.instructions.length) {
        throw StateError('Execution reached the end without HALT.');
      }

      final instruction = bytecode.instructions[_instructionPointer++];

      switch (instruction.opcode) {
        case OpCode.constant:
          final index = instruction.operand;

          if (index is! int ||
              index < 0 ||
              index >= bytecode.constants.length) {
            throw StateError('Invalid constant index: $index');
          }

          _push(bytecode.constants[index]);
          break;

        case OpCode.pop:
          _pop();
          break;

        case OpCode.duplicate:
          if (_stack.isEmpty) {
            throw StateError('Cannot duplicate an empty stack.');
          }

          _push(_stack.last);
          break;

        case OpCode.defineGlobal:
          final name = instruction.operand;

          if (name is! String) {
            throw StateError('Invalid global variable name: $name');
          }

          _currentEnvironment.define(name, _pop());
          break;

        case OpCode.getGlobal:
          final name = instruction.operand;

          if (name is! String) {
            throw StateError('Invalid global variable name: $name');
          }

          _push(_currentEnvironment.get(name));
          break;

        case OpCode.setGlobal:
          final name = instruction.operand;

          if (name is! String) {
            throw StateError('Invalid global variable name: $name');
          }

          _currentEnvironment.assign(name, _pop());
          break;

        case OpCode.add:
          final right = _pop();
          final left = _pop();

          if (left is String || right is String) {
            _push('$left$right');
          } else {
            _push(_number(left) + _number(right));
          }
          break;

        case OpCode.subtract:
          final right = _number(_pop());
          final left = _number(_pop());
          _push(left - right);
          break;

        case OpCode.multiply:
          final right = _number(_pop());
          final left = _number(_pop());
          _push(left * right);
          break;

        case OpCode.divide:
          final right = _number(_pop());
          final left = _number(_pop());
          _push(left / right);
          break;

        case OpCode.modulo:
          final right = _number(_pop());
          final left = _number(_pop());
          _push(left % right);
          break;

        case OpCode.negate:
          _push(-_number(_pop()));
          break;

        case OpCode.equal:
          final right = _pop();
          final left = _pop();
          _push(left == right);
          break;

        case OpCode.notEqual:
          final right = _pop();
          final left = _pop();
          _push(left != right);
          break;

        case OpCode.greater:
          final right = _number(_pop());
          final left = _number(_pop());
          _push(left > right);
          break;

        case OpCode.greaterEqual:
          final right = _number(_pop());
          final left = _number(_pop());
          _push(left >= right);
          break;

        case OpCode.less:
          final right = _number(_pop());
          final left = _number(_pop());
          _push(left < right);
          break;

        case OpCode.lessEqual:
          final right = _number(_pop());
          final left = _number(_pop());
          _push(left <= right);
          break;

        case OpCode.not:
          _push(!_truthy(_pop()));
          break;

        case OpCode.print:
          onPrint(_pop());
          break;

        case OpCode.jump:
          _instructionPointer = _jumpTarget(
            instruction.operand,
            bytecode.instructions.length,
          );
          break;

        case OpCode.jumpIfFalse:
          final target = _jumpTarget(
            instruction.operand,
            bytecode.instructions.length,
          );

          final condition = _pop();

          if (!_truthy(condition)) {
            _instructionPointer = target;
          }
          break;

        case OpCode.loop:
          _instructionPointer = _jumpTarget(
            instruction.operand,
            bytecode.instructions.length,
          );
          break;

        case OpCode.enterScope:
          _currentEnvironment = Environment(enclosing: _currentEnvironment);
          break;

        case OpCode.exitScope:
          final enclosing = _currentEnvironment.enclosing;

          if (enclosing == null) {
            throw StateError('Cannot exit the global scope.');
          }

          _currentEnvironment = enclosing;
          break;

        case OpCode.halt:
          _halted = true;
          break;

        default:
          throw UnsupportedError(
            'VM instruction not implemented: ${instruction.opcode}',
          );
      }
    }
  }

  int _jumpTarget(Object? operand, int instructionCount) {
    if (operand is! int || operand < 0 || operand >= instructionCount) {
      throw StateError('Invalid jump target: $operand');
    }

    return operand;
  }

  double _number(Object? value) {
    if (value is num) {
      return value.toDouble();
    }

    throw Exception('Expected a number, but got ${value.runtimeType}.');
  }

  bool _truthy(Object? value) {
    if (value == null) {
      return false;
    }

    if (value is bool) {
      return value;
    }

    return true;
  }

  void _push(Object? value) {
    _stack.add(value);
  }

  Object? _pop() {
    if (_stack.isEmpty) {
      throw StateError('Stack underflow.');
    }

    return _stack.removeLast();
  }
}
