import 'dart:async';
import 'dart:io';

import 'package:video_editor/utils/notifier.dart';

/// The app's [File] for logging.
final File logFile = File('easy_edits.log')..create();

/// Makes sure that the logile exists before logging.
Future<void> makeSureLogExists() async {
  if (!await logFile.exists()) {
    await logFile.create();
  }
}

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

  await logFile.writeAsString(textTemplate);
}

FutureOr<Null> dumpErrorAndNotify(final Object? error, final StackTrace stackTrace) async {
  dumpErrorLog(error, stackTrace);
  notify(
      'An error occurred. The error has been dumped in a logfile. If you decide to open a report, attach this log.');
}

Future<void> logIntoFile(final String log) async {
  await makeSureLogExists();
  await logFile.writeAsString('${DateTime.now().toIso8601String()} $log', mode: FileMode.writeOnlyAppend);
}
