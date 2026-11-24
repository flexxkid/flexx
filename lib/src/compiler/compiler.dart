import '../ast/expression.dart';
import '../ast/statement.dart';
import '../token/token_type.dart';
import 'bytecode.dart';
import 'instruction.dart';
import 'opcode.dart';

class Compiler {
  final List<Instruction> _instructions = [];
  final List<Object?> _constants = [];

  Bytecode compile(Program program) {
    _instructions.clear();
    _constants.clear();

    for (final statement in program.statements) {
      _compileStatement(statement);
    }

    _emit(OpCode.halt);

    return Bytecode(
      instructions: List.unmodifiable(_instructions),
      constants: List.unmodifiable(_constants),
    );
  }

  void _compileStatement(Statement statement) {
    if (statement is VariableDeclaration) {
      _compileExpression(statement.initializer);
      _emit(OpCode.defineGlobal, statement.name.lexeme);
      return;
    }

    if (statement is PrintStatement) {
      _compileExpression(statement.expression);
      _emit(OpCode.print);
      return;
    }

    if (statement is ExpressionStatement) {
      _compileExpression(statement.expression);
      _emit(OpCode.pop);
      return;
    }

    if (statement is BlockStatement) {
      _compileBlock(statement);
      return;
    }

    if (statement is IfStatement) {
      _compileIf(statement);
      return;
    }

    if (statement is WhileStatement) {
      _compileWhile(statement);
      return;
    }

    throw UnsupportedError('Unsupported statement: ${statement.runtimeType}');
  }

  void _compileBlock(BlockStatement block) {
    _emit(OpCode.enterScope);

    for (final statement in block.statements) {
      _compileStatement(statement);
    }

    _emit(OpCode.exitScope);
  }

  void _compileIf(IfStatement statement) {
    _compileExpression(statement.condition);

    final thenJump = _emitJump(OpCode.jumpIfFalse);

    _compileStatement(statement.thenBranch);

    if (statement.elseBranch != null) {
      final elseJump = _emitJump(OpCode.jump);

      _patchJump(thenJump);

      _compileStatement(statement.elseBranch!);

      _patchJump(elseJump);
    } else {
      _patchJump(thenJump);
    }
  }

  void _compileWhile(WhileStatement statement) {
    final loopStart = _instructions.length;

    _compileExpression(statement.condition);

    final exitJump = _emitJump(OpCode.jumpIfFalse);

    _compileStatement(statement.body);

    // Jump back to the beginning of the condition.
    _emit(OpCode.loop, loopStart);

    _patchJump(exitJump);
  }

  void _compileExpression(Expression expression) {
    if (expression is LiteralExpression) {
      _compileLiteral(expression);
      return;
    }

    if (expression is VariableExpression) {
      _emit(OpCode.getGlobal, expression.name.lexeme);
      return;
    }

    if (expression is GroupingExpression) {
      _compileExpression(expression.expression);
      return;
    }

    if (expression is UnaryExpression) {
      _compileUnary(expression);
      return;
    }

    if (expression is BinaryExpression) {
      _compileBinary(expression);
      return;
    }

    if (expression is AssignExpression) {
      _compileExpression(expression.value);
      _emit(OpCode.duplicate);
      _emit(OpCode.setGlobal, expression.name.lexeme);
      return;
    }

    throw UnsupportedError('Unsupported expression: ${expression.runtimeType}');
  }

  void _compileLiteral(LiteralExpression expression) {
    final value = expression.value;

    if (value is num || value is String || value is bool) {
      final index = _addConstant(value);
      _emit(OpCode.constant, index);
      return;
    }

    throw UnsupportedError('Unsupported literal: $value');
  }

  void _compileUnary(UnaryExpression expression) {
    _compileExpression(expression.right);

    switch (expression.operator.type) {
      case TokenType.minus:
        _emit(OpCode.negate);
        break;

      case TokenType.plus:
        break;

      case TokenType.not:
        _emit(OpCode.not);
        break;

      default:
        throw UnsupportedError(
          'Unsupported unary operator: ${expression.operator.lexeme}',
        );
    }
  }

  void _compileBinary(BinaryExpression expression) {
    final operatorType = expression.operator.type;

    if (operatorType == TokenType.and) {
      _compileLogicalAnd(expression);
      return;
    }

    if (operatorType == TokenType.or) {
      _compileLogicalOr(expression);
      return;
    }

    _compileExpression(expression.left);
    _compileExpression(expression.right);

    switch (operatorType) {
      case TokenType.plus:
        _emit(OpCode.add);
        break;

      case TokenType.minus:
        _emit(OpCode.subtract);
        break;

      case TokenType.multiply:
        _emit(OpCode.multiply);
        break;

      case TokenType.divide:
        _emit(OpCode.divide);
        break;

      case TokenType.modulo:
        _emit(OpCode.modulo);
        break;

      case TokenType.equal:
        _emit(OpCode.equal);
        break;

      case TokenType.notEqual:
        _emit(OpCode.notEqual);
        break;

      case TokenType.greater:
        _emit(OpCode.greater);
        break;

      case TokenType.greaterEqual:
        _emit(OpCode.greaterEqual);
        break;

      case TokenType.less:
        _emit(OpCode.less);
        break;

      case TokenType.lessEqual:
        _emit(OpCode.lessEqual);
        break;

      default:
        throw UnsupportedError(
          'Unsupported binary operator: ${expression.operator.lexeme}',
        );
    }
  }

  void _compileLogicalAnd(BinaryExpression expression) {
    _compileExpression(expression.left);

    // A false left operand skips evaluation of the right operand.
    final falseJump = _emitJump(OpCode.jumpIfFalse);

    _compileExpression(expression.right);

    // Normalize the right operand to a boolean.
    _emit(OpCode.not);
    _emit(OpCode.not);

    final endJump = _emitJump(OpCode.jump);

    _patchJump(falseJump);

    _emitConstant(false);

    _patchJump(endJump);
  }

  void _compileLogicalOr(BinaryExpression expression) {
    _compileExpression(expression.left);

    // A true left operand skips evaluation of the right operand.
    final rightJump = _emitJump(OpCode.jumpIfFalse);

    _emitConstant(true);

    final endJump = _emitJump(OpCode.jump);

    _patchJump(rightJump);

    _compileExpression(expression.right);

    // Normalize the right operand to a boolean.
    _emit(OpCode.not);
    _emit(OpCode.not);

    _patchJump(endJump);
  }

  void _emitConstant(Object? value) {
    final index = _addConstant(value);
    _emit(OpCode.constant, index);
  }

  int _addConstant(Object? value) {
    _constants.add(value);
    return _constants.length - 1;
  }

  void _emit(OpCode opcode, [Object? operand]) {
    _instructions.add(Instruction(opcode, operand));
  }

  int _emitJump(OpCode opcode) {
    final index = _instructions.length;
    _emit(opcode, -1);
    return index;
  }

  void _patchJump(int instructionIndex) {
    final instruction = _instructions[instructionIndex];

    _instructions[instructionIndex] = Instruction(
      instruction.opcode,
      _instructions.length,
    );
  }
}
