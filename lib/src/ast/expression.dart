import '../token/token.dart';

abstract class Expression {
  const Expression();
}

class LiteralExpression extends Expression {
  final Object? value;

  const LiteralExpression(this.value);
}

class VariableExpression extends Expression {
  final Token name;

  const VariableExpression(this.name);
}

class BinaryExpression extends Expression {
  final Expression left;
  final Token operator;
  final Expression right;

  const BinaryExpression(this.left, this.operator, this.right);
}

class UnaryExpression extends Expression {
  final Token operator;
  final Expression right;

  const UnaryExpression(this.operator, this.right);
}

class GroupingExpression extends Expression {
  final Expression expression;

  const GroupingExpression(this.expression);
}
