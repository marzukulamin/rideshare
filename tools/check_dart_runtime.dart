import 'dart:io';

void main() {
  try {
    if (Platform.resolvedExecutable.isEmpty) {
      throw StateError('Dart executable path is empty.');
    }
    stdout.writeln('Dart runtime startup check passed.');
  } catch (_) {
    stderr.writeln(
      'Dart cannot resolve its executable in this Windows process environment. '
      'Run the project build in a normal PowerShell session or an approved '
      'execution outside the restricted process sandbox. This failure occurs '
      'before the mobile app starts.',
    );
    exitCode = 1;
  }
}
