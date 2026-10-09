import '../ast/expression.dart';
import '../ast/statement.dart';
import '../token/token.dart';
import '../token/token_type.dart';

class Parser {
  final List<Token> tokens;
  int _current = 0;

  Parser(this.tokens);

  Program parse() {
    _consume(
      TokenType.flexx,
      'Expected "Flexx" at the beginning of the program.',
    );

    _consume(TokenType.leftBrace, 'Expected "{" after Flexx.');

    final statements = <Statement>[];

    while (!_check(TokenType.rightBrace) && !_isAtEnd()) {
      statements.add(_statement());
    }

    _consume(TokenType.rightBrace, 'Expected "}" after program.');

    _consume(TokenType.eof, 'Expected end of file after program.');

    return Program(statements);
  }

  Statement _statement() {
    if (_match(TokenType.let)) {
      return _variableDeclaration();
    }

    if (_match(TokenType.print)) {
      return _printStatement();
    }

    return _expressionStatement();
  }

  Statement _variableDeclaration() {
    final name = _consume(TokenType.identifier, 'Expected variable name.');

    _consume(TokenType.assign, 'Expected "=" after variable name.');

    final initializer = _expression();

    _consume(TokenType.semicolon, 'Expected ";" after variable declaration.');

    return VariableDeclaration(name, initializer);
  }

  Statement _printStatement() {
    final expression = _expression();

    _consume(TokenType.semicolon, 'Expected ";" after value.');

    return PrintStatement(expression);
  }

  Statement _expressionStatement() {
    final expression = _expression();

    _consume(TokenType.semicolon, 'Expected ";" after expression.');

    return ExpressionStatement(expression);
  }

  Expression _expression() {
    return _or();
  }

  Expression _or() {
    var expression = _and();

    while (_match(TokenType.or)) {
      final operator = _previous();
      final right = _and();

      expression = BinaryExpression(expression, operator, right);
    }

    return expression;
  }

  Expression _and() {
    var expression = _equality();

    while (_match(TokenType.and)) {
      final operator = _previous();
      final right = _equality();

      expression = BinaryExpression(expression, operator, right);
    }

    return expression;
  }

  Expression _equality() {
    var expression = _comparison();

    while (_match(TokenType.equal, TokenType.notEqual)) {
      final operator = _previous();
      final right = _comparison();

      expression = BinaryExpression(expression, operator, right);
    }

    return expression;
  }

  Expression _comparison() {
    var expression = _term();

    while (_match(
      TokenType.greater,
      TokenType.greaterEqual,
      TokenType.less,
      TokenType.lessEqual,
    )) {
      final operator = _previous();
      final right = _term();

      expression = BinaryExpression(expression, operator, right);
    }

    return expression;
  }

  Expression _term() {
    var expression = _factor();

    while (_match(TokenType.plus, TokenType.minus)) {
      final operator = _previous();
      final right = _factor();

      expression = BinaryExpression(expression, operator, right);
    }

    return expression;
  }

  Expression _factor() {
    var expression = _unary();

    while (_match(TokenType.multiply, TokenType.divide, TokenType.modulo)) {
      final operator = _previous();
      final right = _unary();

      expression = BinaryExpression(expression, operator, right);
    }

    return expression;
  }

  Expression _unary() {
    if (_match(TokenType.not, TokenType.minus, TokenType.plus)) {
      final operator = _previous();
      final right = _unary();

      return UnaryExpression(operator, right);
    }

    return _primary();
  }

  Expression _primary() {
    if (_match(TokenType.number)) {
      return LiteralExpression(_previous().literal);
    }

    if (_match(TokenType.trueKeyword)) {
      return const LiteralExpression(true);
    }

    if (_match(TokenType.falseKeyword)) {
      return const LiteralExpression(false);
    }

    if (_match(TokenType.string)) {
      return LiteralExpression(_previous().literal);
    }

    if (_match(TokenType.identifier)) {
      return VariableExpression(_previous());
    }

    // Keep the remaining code unchanged.

    if (_match(TokenType.leftParen)) {
      final expression = _expression();

      _consume(TokenType.rightParen, 'Expected ")" after expression.');

      return GroupingExpression(expression);
    }

    throw _error(_peek(), 'Expected expression.');
  }

  bool _match(
    TokenType first, [
    TokenType? second,
    TokenType? third,
    TokenType? fourth,
  ]) {
    if (_check(first)) {
      _advance();
      return true;
    }

    if (second != null && _check(second)) {
      _advance();
      return true;
    }

    if (third != null && _check(third)) {
      _advance();
      return true;
    }

    if (fourth != null && _check(fourth)) {
      _advance();
      return true;
    }

    return false;
  }

  Token _consume(TokenType type, String message) {
    if (_check(type)) {
      return _advance();
    }

    throw _error(_peek(), message);
  }

  bool _check(TokenType type) {
    if (_isAtEnd()) {
      return type == TokenType.eof;
    }

    return _peek().type == type;
  }

  Token _advance() {
    if (!_isAtEnd()) {
      _current++;
    }

    return _previous();
  }

  bool _isAtEnd() {
    return _peek().type == TokenType.eof;
  }

  Token _peek() {
    return tokens[_current];
  }

  Token _previous() {
    return tokens[_current - 1];
  }

  Exception _error(Token token, String message) {
    return FormatException(
      '$message Line ${token.line}, column ${token.column}.',
    );
  }
}
