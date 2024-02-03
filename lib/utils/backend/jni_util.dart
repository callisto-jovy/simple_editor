import 'dart:io';

import 'package:jni/jni.dart';
import 'package:path/path.dart';

const jarError = 'No JAR files were found.\n'
    'Run `dart run jnigen:download_maven_jars --config jnigen.yaml` '
    'in plugin directory.\n'
    'Alternatively, regenerate JNI bindings in plugin directory, which will '
    'automatically download the JAR files.';
// It's required to manually provide the JAR files as classpath when
// spawning the JVM.
const jarDir = 'mvn_jar';


void spawnJNI() {
  final List<String> jars;
  try {
    jars = Directory(jarDir)
        .listSync()
        .map((e) => e.path)
        .where((path) => path.endsWith('.jar'))
        .toList();
  } on OSError catch (_) {
    stderr.writeln(jarError);
    return;
  }
  if (jars.isEmpty) {
    stderr.writeln(jarError);
    return;
  }

  Jni.spawn(
    dylibDir: join('build', 'jni_libs'),
    classPath: ['easy_edits/core/target/classes', ...jars],
  );
}