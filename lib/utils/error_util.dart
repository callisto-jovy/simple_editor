import 'dart:io';


Future<void> dumpErrorLog(final Object? error, final StackTrace stackTrace) async {
  final File logFile = File('error_log ${DateTime.now().toIso8601String()}');

  final String textTemplate = '''

----- Easy Edits Error log ----

Program failed with exception.

Time: ${DateTime.now().toIso8601String()} 
Error: $error
Stacktrace ${stackTrace.toString()}


---- End error log -----
''';

  logFile.writeAsString(textTemplate);
}
