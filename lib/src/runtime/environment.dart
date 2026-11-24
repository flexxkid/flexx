class Environment {
  final Environment? enclosing;

  final Map<String, Object?> _values = {'PI': 3.141592653589793};

  Environment({this.enclosing});

  void define(String name, Object? value) {
    _values[name] = value;
  }

  Object? get(String name) {
    if (_values.containsKey(name)) {
      return _values[name];
    }

    if (enclosing != null) {
      return enclosing!.get(name);
    }

    throw Exception('Undefined variable "$name".');
  }

  void assign(String name, Object? value) {
    if (_values.containsKey(name)) {
      _values[name] = value;
      return;
    }

    if (enclosing != null) {
      enclosing!.assign(name, value);
      return;
    }

    throw Exception('Undefined variable "$name".');
  }
}
