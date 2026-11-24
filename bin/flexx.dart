import 'dart:io';

import 'package:flexx/src/compiler/compiler.dart';
import 'package:flexx/src/lexer/lexer.dart';
import 'package:flexx/src/parser/parser.dart';
import 'package:flexx/src/vm/virtual_machine.dart';

Future<void> main(List<String> args) async {
  if (args.length != 1) {
    stderr.writeln('Usage: dart run bin/flexx.dart <file.flexx>');
    exitCode = 64;
    return;
  }

  final file = File(args.single);

  if (!await file.exists()) {
    stderr.writeln('Flexx file not found: ${args.single}');
    exitCode = 66;
    return;
  }

  try {
    final source = await file.readAsString();
    final tokens = Lexer(source).scanTokens();
    final program = Parser(tokens).parse();
    final bytecode = Compiler().compile(program);

    VirtualMachine().run(bytecode);
  } catch (error) {
    stderr.writeln('Flexx error: $error');
    exitCode = 1;
  }
}
