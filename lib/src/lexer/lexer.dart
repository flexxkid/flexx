import '../token/token.dart';
import '../token/token_type.dart';

class Lexer {
  final String source;

  int _current = 0;
  int _start = 0;
  int _line = 1;
  int _column = 1;

  final List<Token> _tokens = [];

  Lexer(this.source);

  List<Token> scanTokens() {
    while (!_isAtEnd()) {
      _start = _current;
      _scanToken();
    }

    _tokens.add(
      Token(type: TokenType.eof, lexeme: '', line: _line, column: _column),
    );

    return _tokens;
  }

  void _scanToken() {
    final character = _advance();

    switch (character) {
      // Arithmetic operators
      case '+':
        _addToken(TokenType.plus);
        break;

      case '-':
        _addToken(TokenType.minus);
        break;

      case '*':
        _addToken(TokenType.multiply);
        break;

      case '/':
        _addToken(TokenType.divide);
        break;

      case '%':
        _addToken(TokenType.modulo);
        break;

      // Assignment / comparison
      case '=':
        _addToken(_match('=') ? TokenType.equal : TokenType.assign);
        break;

      case '!':
        _addToken(_match('=') ? TokenType.notEqual : TokenType.not);
        break;

      case '>':
        _addToken(_match('=') ? TokenType.greaterEqual : TokenType.greater);
        break;

      case '<':
        _addToken(_match('=') ? TokenType.lessEqual : TokenType.less);
        break;

      // Logical operators
      case '&':
        if (_match('&')) {
          _addToken(TokenType.and);
        } else {
          _error('Expected "&" after "&".');
        }
        break;

      case '|':
        if (_match('|')) {
          _addToken(TokenType.or);
        } else {
          _error('Expected "|" after "|".');
        }
        break;

      // Delimiters
      case ';':
        _addToken(TokenType.semicolon);
        break;

      case ',':
        _addToken(TokenType.comma);
        break;

      case '.':
        _addToken(TokenType.dot);
        break;

      case '(':
        _addToken(TokenType.leftParen);
        break;

      case ')':
        _addToken(TokenType.rightParen);
        break;

      case '{':
        _addToken(TokenType.leftBrace);
        break;

      case '}':
        _addToken(TokenType.rightBrace);
        break;

      case '[':
        _addToken(TokenType.leftBracket);
        break;

      case ']':
        _addToken(TokenType.rightBracket);
        break;

      // Whitespace
      case ' ':
      case '\r':
      case '\t':
        break;

      case '\n':
        _line++;
        _column = 1;
        break;

      // String
      case '"':
        _string();
        break;

      default:
        if (_isDigit(character)) {
          _number();
        } else if (_isAlpha(character)) {
          _identifier();
        } else {
          _error('Unexpected character "$character".');
        }
    }
  }

  // ------------------------------------------------------------
  // Strings
  // ------------------------------------------------------------

  void _string() {
    while (!_isAtEnd() && _peek() != '"') {
      if (_peek() == '\n') {
        _line++;
        _column = 1;
      }

      _advance();
    }

    if (_isAtEnd()) {
      _error('Unterminated string.');
      return;
    }

    // Consume closing quote.
    _advance();

    final value = source.substring(_start + 1, _current - 1);

    _addToken(TokenType.string, value);
  }

  // ------------------------------------------------------------
  // Numbers
  // ------------------------------------------------------------

  void _number() {
    while (!_isAtEnd() && _isDigit(_peek())) {
      _advance();
    }

    // Decimal number.
    if (_peek() == '.' && _isDigit(_peekNext())) {
      _advance();

      while (!_isAtEnd() && _isDigit(_peek())) {
        _advance();
      }
    }

    final text = source.substring(_start, _current);

    final value = double.parse(text);

    _addToken(TokenType.number, value);
  }

  // ------------------------------------------------------------
  // Identifiers and keywords
  // ------------------------------------------------------------

  void _identifier() {
    while (!_isAtEnd() && _isAlphaNumeric(_peek())) {
      _advance();
    }

    final text = source.substring(_start, _current);

    final type = keywords[text];

    if (type != null) {
      _addToken(type);
    } else {
      _addToken(TokenType.identifier);
    }
  }

  // ------------------------------------------------------------
  // Keywords
  // ------------------------------------------------------------
  final keywords = {
    'Flexx': TokenType.flexx,
    'print': TokenType.print,
    'let': TokenType.let,
    'true': TokenType.trueKeyword,
    'false': TokenType.falseKeyword,
  };

  // ------------------------------------------------------------
  // Character handling
  // ------------------------------------------------------------

  String _advance() {
    final character = source[_current];

    _current++;
    _column++;

    return character;
  }

  bool _match(String expected) {
    if (_isAtEnd()) {
      return false;
    }

    if (source[_current] != expected) {
      return false;
    }

    _current++;
    _column++;

    return true;
  }

  String _peek() {
    if (_isAtEnd()) {
      return '\u0000';
    }

    return source[_current];
  }

  String _peekNext() {
    if (_current + 1 >= source.length) {
      return '\u0000';
    }

    return source[_current + 1];
  }

  bool _isAtEnd() {
    return _current >= source.length;
  }

  bool _isDigit(String character) {
    return character.codeUnitAt(0) >= 48 && character.codeUnitAt(0) <= 57;
  }

  bool _isAlpha(String character) {
    return (character.codeUnitAt(0) >= 65 && character.codeUnitAt(0) <= 90) ||
        (character.codeUnitAt(0) >= 97 && character.codeUnitAt(0) <= 122) ||
        character == '_';
  }

  bool _isAlphaNumeric(String character) {
    return _isAlpha(character) || _isDigit(character);
  }

  // ------------------------------------------------------------
  // Token creation
  // ------------------------------------------------------------

  void _addToken(TokenType type, [Object? literal]) {
    final text = source.substring(_start, _current);

    _tokens.add(
      Token(
        type: type,
        lexeme: text,
        literal: literal,
        line: _line,
        column: _column - (_current - _start),
      ),
    );
  }

  // ------------------------------------------------------------
  // Errors
  // ------------------------------------------------------------

  void _error(String message) {
    throw FormatException(
      'Lexer error at line $_line, '
      'column $_column: $message',
    );
  }
}
