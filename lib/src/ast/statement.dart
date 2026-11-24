import '../token/token.dart';
import 'expression.dart';

class Program {
  final List<Statement> statements;

  const Program(this.statements);
}

abstract class Statement {
  const Statement();
}

class ExpressionStatement extends Statement {
  final Expression expression;

  const ExpressionStatement(this.expression);
}

class PrintStatement extends Statement {
  final Expression expression;

  const PrintStatement(this.expression);
}

class VariableDeclaration extends Statement {
  final Token name;
  final Expression initializer;

  const VariableDeclaration(this.name, this.initializer);
}

class IfStatement extends Statement {
  final Expression condition;
  final Statement thenBranch;
  final Statement? elseBranch;

  const IfStatement(this.condition, this.thenBranch, this.elseBranch);
}

class BlockStatement extends Statement {
  final List<Statement> statements;

  const BlockStatement(this.statements);
}

class WhileStatement extends Statement {
  final Expression condition;
  final Statement body;

  const WhileStatement(this.condition, this.body);
}
