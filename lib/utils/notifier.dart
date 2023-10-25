import 'package:local_notifier/local_notifier.dart';

Future<void> notify(final String message) {
  return LocalNotification(
    title: 'Easy Edits',
    body: message,
  ).show();
}
