import '../ast/expression.dart';
import '../ast/statement.dart';
import '../runtime/environment.dart';
import '../token/token_type.dart';

class Interpreter {
  final Environment environment;

  Interpreter(this.environment);

  void interpret(Program program) {
    for (final statement in program.statements) {
      _execute(statement);
    }
  }

  void _execute(Statement statement) {
    if (statement is VariableDeclaration) {
      final value = _evaluate(statement.initializer);

      environment.define(statement.name.lexeme, value);
      return;
    }

    if (statement is PrintStatement) {
      print(_evaluate(statement.expression));
      return;
    }

    if (statement is ExpressionStatement) {
      _evaluate(statement.expression);
      return;
    }

    throw Exception('Unsupported statement: ${statement.runtimeType}');
  }

  Object? _evaluate(Expression expression) {
    if (expression is LiteralExpression) {
      return expression.value;
    }

    if (expression is VariableExpression) {
      return environment.get(expression.name.lexeme);
    }

    if (expression is GroupingExpression) {
      return _evaluate(expression.expression);
    }

    if (expression is UnaryExpression) {
      final right = _evaluate(expression.right);

      switch (expression.operator.type) {
        case TokenType.minus:
          return -_number(right);

        case TokenType.plus:
          return _number(right);

        case TokenType.not:
          return !_truthy(right);

        default:
          throw Exception(
            'Unsupported unary operator '
            '"${expression.operator.lexeme}".',
          );
      }
    }

    if (expression is BinaryExpression) {
      return _evaluateBinary(expression);
    }

    throw Exception('Unsupported expression: ${expression.runtimeType}');
  }

  Object? _evaluateBinary(BinaryExpression expression) {
    final operatorType = expression.operator.type;

    // Logical AND: stop immediately if the left operand is false.
    if (operatorType == TokenType.and) {
      final left = _evaluate(expression.left);

      if (!_truthy(left)) {
        return false;
      }

      return _truthy(_evaluate(expression.right));
    }

    // Logical OR: stop immediately if the left operand is true.
    if (operatorType == TokenType.or) {
      final left = _evaluate(expression.left);

      if (_truthy(left)) {
        return true;
      }

      return _truthy(_evaluate(expression.right));
    }

    // Evaluate both operands for non-logical binary operators.
    final left = _evaluate(expression.left);
    final right = _evaluate(expression.right);

    switch (operatorType) {
      case TokenType.plus:
        if (left is String || right is String) {
          return '$left$right';
        }

        return _number(left) + _number(right);

      case TokenType.minus:
        return _number(left) - _number(right);

      case TokenType.multiply:
        return _number(left) * _number(right);

      case TokenType.divide:
        return _number(left) / _number(right);

      case TokenType.modulo:
        return _number(left) % _number(right);

      case TokenType.equal:
        return left == right;

      case TokenType.notEqual:
        return left != right;

      case TokenType.greater:
        return _number(left) > _number(right);

      case TokenType.greaterEqual:
        return _number(left) >= _number(right);

      case TokenType.less:
        return _number(left) < _number(right);

      case TokenType.lessEqual:
        return _number(left) <= _number(right);

      default:
        throw Exception(
          'Unsupported binary operator '
          '"${expression.operator.lexeme}".',
        );
    }
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
}
