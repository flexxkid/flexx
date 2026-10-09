class Environment {
  final Map<String, Object?> _values = {'PI': 3.141592653589793};

  void define(String name, Object? value) {
    _values[name] = value;
  }

  Object? get(String name) {
    if (!_values.containsKey(name)) {
      throw Exception('Undefined variable "$name".');
    }

    return _values[name];
  }
}
