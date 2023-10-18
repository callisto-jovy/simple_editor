// Autogenerated by jnigen. DO NOT EDIT!

// ignore_for_file: annotate_overrides
// ignore_for_file: camel_case_extensions
// ignore_for_file: camel_case_types
// ignore_for_file: constant_identifier_names
// ignore_for_file: file_names
// ignore_for_file: lines_longer_than_80_chars
// ignore_for_file: no_leading_underscores_for_local_identifiers
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: overridden_fields
// ignore_for_file: unnecessary_cast
// ignore_for_file: unused_element
// ignore_for_file: unused_field
// ignore_for_file: unused_import
// ignore_for_file: unused_local_variable
// ignore_for_file: unused_shown_name

import "dart:isolate" show ReceivePort;
import "dart:ffi" as ffi;
import "package:jni/internal_helpers_for_jnigen.dart";
import "package:jni/jni.dart" as jni;

// Auto-generated initialization code.

final ffi.Pointer<T> Function<T extends ffi.NativeType>(String sym) jniLookup =
    ProtectedJniExtensions.initGeneratedLibrary("easy_edits");

/// from: de.yugata.easy.edits.audio.AudioAnalyser
class AudioAnalyser extends jni.JObject {
  @override
  late final jni.JObjType<AudioAnalyser> $type = type;

  AudioAnalyser.fromRef(
    jni.JObjectPtr ref,
  ) : super.fromRef(ref);

  /// The type which includes information such as the signature of this class.
  static const type = $AudioAnalyserType();
  static final _new0 = jniLookup<ffi.NativeFunction<jni.JniResult Function()>>(
          "AudioAnalyser__new0")
      .asFunction<jni.JniResult Function()>();

  /// from: public void <init>()
  /// The returned object must be released after use, by calling the [release] method.
  factory AudioAnalyser() {
    return AudioAnalyser.fromRef(_new0().object);
  }

  static final _analyseBeats = jniLookup<
          ffi.NativeFunction<
              jni.JniResult Function(ffi.Pointer<ffi.Void>, ffi.Double,
                  ffi.Double)>>("AudioAnalyser__analyseBeats")
      .asFunction<
          jni.JniResult Function(ffi.Pointer<ffi.Void>, double, double)>();

  /// from: static public java.util.List analyseBeats(java.lang.String string, double d, double d1)
  /// The returned object must be released after use, by calling the [release] method.
  static jni.JList<jni.JDouble> analyseBeats(
    jni.JString string,
    double d,
    double d1,
  ) {
    return const jni.JListType(jni.JDoubleType())
        .fromRef(_analyseBeats(string.reference, d, d1).object);
  }

  static final _analyseStamps = jniLookup<
          ffi.NativeFunction<
              jni.JniResult Function(ffi.Pointer<ffi.Void>, ffi.Double,
                  ffi.Double)>>("AudioAnalyser__analyseStamps")
      .asFunction<
          jni.JniResult Function(ffi.Pointer<ffi.Void>, double, double)>();

  /// from: static public java.util.List analyseStamps(java.lang.String string, double d, double d1)
  /// The returned object must be released after use, by calling the [release] method.
  static jni.JList<jni.JDouble> analyseStamps(
    jni.JString string,
    double d,
    double d1,
  ) {
    return const jni.JListType(jni.JDoubleType())
        .fromRef(_analyseStamps(string.reference, d, d1).object);
  }

  static final _analyseBeats1 = jniLookup<
          ffi.NativeFunction<
              jni.JniResult Function(
                  ffi.Pointer<ffi.Void>,
                  ffi.Double,
                  ffi.Double,
                  ffi.Pointer<ffi.Void>)>>("AudioAnalyser__analyseBeats1")
      .asFunction<
          jni.JniResult Function(
              ffi.Pointer<ffi.Void>, double, double, ffi.Pointer<ffi.Void>)>();

  /// from: static public void analyseBeats(java.lang.String string, double d, double d1, be.tarsos.dsp.onsets.OnsetHandler onsetHandler)
  static void analyseBeats1(
    jni.JString string,
    double d,
    double d1,
    jni.JObject onsetHandler,
  ) {
    return _analyseBeats1(string.reference, d, d1, onsetHandler.reference)
        .check();
  }
}

final class $AudioAnalyserType extends jni.JObjType<AudioAnalyser> {
  const $AudioAnalyserType();

  @override
  String get signature => r"Lde/yugata/easy/edits/audio/AudioAnalyser;";

  @override
  AudioAnalyser fromRef(jni.JObjectPtr ref) => AudioAnalyser.fromRef(ref);

  @override
  jni.JObjType get superType => const jni.JObjectType();

  @override
  final superCount = 1;

  @override
  int get hashCode => ($AudioAnalyserType).hashCode;

  @override
  bool operator ==(Object other) {
    return other.runtimeType == ($AudioAnalyserType) &&
        other is $AudioAnalyserType;
  }
}

/// from: de.yugata.easy.edits.editor.FlutterWrapper$FlutterFilterWrapper
class FlutterWrapper_FlutterFilterWrapper extends jni.JObject {
  @override
  late final jni.JObjType<FlutterWrapper_FlutterFilterWrapper> $type = type;

  FlutterWrapper_FlutterFilterWrapper.fromRef(
    jni.JObjectPtr ref,
  ) : super.fromRef(ref);

  /// The type which includes information such as the signature of this class.
  static const type = $FlutterWrapper_FlutterFilterWrapperType();
  static final _new0 = jniLookup<
              ffi.NativeFunction<
                  jni.JniResult Function(
                      ffi.Pointer<ffi.Void>,
                      ffi.Pointer<ffi.Void>,
                      ffi.Pointer<ffi.Void>,
                      ffi.Pointer<ffi.Void>,
                      ffi.Pointer<ffi.Void>,
                      ffi.Pointer<ffi.Void>)>>(
          "FlutterWrapper_FlutterFilterWrapper__new0")
      .asFunction<
          jni.JniResult Function(
              ffi.Pointer<ffi.Void>,
              ffi.Pointer<ffi.Void>,
              ffi.Pointer<ffi.Void>,
              ffi.Pointer<ffi.Void>,
              ffi.Pointer<ffi.Void>,
              ffi.Pointer<ffi.Void>)>();

  /// from: public void <init>(java.lang.String string, java.lang.String string1, java.lang.String string2, java.lang.String string3, de.yugata.easy.edits.editor.filter.FilterType filterType, java.util.List list)
  /// The returned object must be released after use, by calling the [release] method.
  factory FlutterWrapper_FlutterFilterWrapper(
    jni.JString string,
    jni.JString string1,
    jni.JString string2,
    jni.JString string3,
    FilterType filterType,
    jni.JList<FilterValue> list,
  ) {
    return FlutterWrapper_FlutterFilterWrapper.fromRef(_new0(
            string.reference,
            string1.reference,
            string2.reference,
            string3.reference,
            filterType.reference,
            list.reference)
        .object);
  }

  static final _getHelpText = jniLookup<
              ffi
              .NativeFunction<jni.JniResult Function(ffi.Pointer<ffi.Void>)>>(
          "FlutterWrapper_FlutterFilterWrapper__getHelpText")
      .asFunction<jni.JniResult Function(ffi.Pointer<ffi.Void>)>();

  /// from: public java.lang.String getHelpText()
  /// The returned object must be released after use, by calling the [release] method.
  jni.JString getHelpText() {
    return const jni.JStringType().fromRef(_getHelpText(reference).object);
  }

  static final _getName = jniLookup<
              ffi
              .NativeFunction<jni.JniResult Function(ffi.Pointer<ffi.Void>)>>(
          "FlutterWrapper_FlutterFilterWrapper__getName")
      .asFunction<jni.JniResult Function(ffi.Pointer<ffi.Void>)>();

  /// from: public java.lang.String getName()
  /// The returned object must be released after use, by calling the [release] method.
  jni.JString getName() {
    return const jni.JStringType().fromRef(_getName(reference).object);
  }

  static final _getDisplayName = jniLookup<
              ffi
              .NativeFunction<jni.JniResult Function(ffi.Pointer<ffi.Void>)>>(
          "FlutterWrapper_FlutterFilterWrapper__getDisplayName")
      .asFunction<jni.JniResult Function(ffi.Pointer<ffi.Void>)>();

  /// from: public java.lang.String getDisplayName()
  /// The returned object must be released after use, by calling the [release] method.
  jni.JString getDisplayName() {
    return const jni.JStringType().fromRef(_getDisplayName(reference).object);
  }

  static final _getDescription = jniLookup<
              ffi
              .NativeFunction<jni.JniResult Function(ffi.Pointer<ffi.Void>)>>(
          "FlutterWrapper_FlutterFilterWrapper__getDescription")
      .asFunction<jni.JniResult Function(ffi.Pointer<ffi.Void>)>();

  /// from: public java.lang.String getDescription()
  /// The returned object must be released after use, by calling the [release] method.
  jni.JString getDescription() {
    return const jni.JStringType().fromRef(_getDescription(reference).object);
  }

  static final _getFilterType = jniLookup<
              ffi
              .NativeFunction<jni.JniResult Function(ffi.Pointer<ffi.Void>)>>(
          "FlutterWrapper_FlutterFilterWrapper__getFilterType")
      .asFunction<jni.JniResult Function(ffi.Pointer<ffi.Void>)>();

  /// from: public de.yugata.easy.edits.editor.filter.FilterType getFilterType()
  /// The returned object must be released after use, by calling the [release] method.
  FilterType getFilterType() {
    return const $FilterTypeType().fromRef(_getFilterType(reference).object);
  }

  static final _getValues = jniLookup<
              ffi
              .NativeFunction<jni.JniResult Function(ffi.Pointer<ffi.Void>)>>(
          "FlutterWrapper_FlutterFilterWrapper__getValues")
      .asFunction<jni.JniResult Function(ffi.Pointer<ffi.Void>)>();

  /// from: public java.util.List getValues()
  /// The returned object must be released after use, by calling the [release] method.
  jni.JList<FilterValue> getValues() {
    return const jni.JListType($FilterValueType())
        .fromRef(_getValues(reference).object);
  }

  static final _toString1 = jniLookup<
              ffi
              .NativeFunction<jni.JniResult Function(ffi.Pointer<ffi.Void>)>>(
          "FlutterWrapper_FlutterFilterWrapper__toString1")
      .asFunction<jni.JniResult Function(ffi.Pointer<ffi.Void>)>();

  /// from: public java.lang.String toString()
  /// The returned object must be released after use, by calling the [release] method.
  jni.JString toString1() {
    return const jni.JStringType().fromRef(_toString1(reference).object);
  }
}

final class $FlutterWrapper_FlutterFilterWrapperType
    extends jni.JObjType<FlutterWrapper_FlutterFilterWrapper> {
  const $FlutterWrapper_FlutterFilterWrapperType();

  @override
  String get signature =>
      r"Lde/yugata/easy/edits/editor/FlutterWrapper$FlutterFilterWrapper;";

  @override
  FlutterWrapper_FlutterFilterWrapper fromRef(jni.JObjectPtr ref) =>
      FlutterWrapper_FlutterFilterWrapper.fromRef(ref);

  @override
  jni.JObjType get superType => const jni.JObjectType();

  @override
  final superCount = 1;

  @override
  int get hashCode => ($FlutterWrapper_FlutterFilterWrapperType).hashCode;

  @override
  bool operator ==(Object other) {
    return other.runtimeType == ($FlutterWrapper_FlutterFilterWrapperType) &&
        other is $FlutterWrapper_FlutterFilterWrapperType;
  }
}

/// from: de.yugata.easy.edits.editor.FlutterWrapper
class FlutterWrapper extends jni.JObject {
  @override
  late final jni.JObjType<FlutterWrapper> $type = type;

  FlutterWrapper.fromRef(
    jni.JObjectPtr ref,
  ) : super.fromRef(ref);

  /// The type which includes information such as the signature of this class.
  static const type = $FlutterWrapperType();
  static final _new0 = jniLookup<ffi.NativeFunction<jni.JniResult Function()>>(
          "FlutterWrapper__new0")
      .asFunction<jni.JniResult Function()>();

  /// from: public void <init>()
  /// The returned object must be released after use, by calling the [release] method.
  factory FlutterWrapper() {
    return FlutterWrapper.fromRef(_new0().object);
  }

  static final _getFilters =
      jniLookup<ffi.NativeFunction<jni.JniResult Function()>>(
              "FlutterWrapper__getFilters")
          .asFunction<jni.JniResult Function()>();

  /// from: static public java.util.List getFilters()
  /// The returned object must be released after use, by calling the [release] method.
  static jni.JList<FlutterWrapper_FlutterFilterWrapper> getFilters() {
    return const jni.JListType($FlutterWrapper_FlutterFilterWrapperType())
        .fromRef(_getFilters().object);
  }

  static final _exportSegments = jniLookup<
              ffi
              .NativeFunction<jni.JniResult Function(ffi.Pointer<ffi.Void>)>>(
          "FlutterWrapper__exportSegments")
      .asFunction<jni.JniResult Function(ffi.Pointer<ffi.Void>)>();

  /// from: static public void exportSegments(java.lang.String string)
  static void exportSegments(
    jni.JString string,
  ) {
    return _exportSegments(string.reference).check();
  }

  static final _edit = jniLookup<
              ffi
              .NativeFunction<jni.JniResult Function(ffi.Pointer<ffi.Void>)>>(
          "FlutterWrapper__edit")
      .asFunction<jni.JniResult Function(ffi.Pointer<ffi.Void>)>();

  /// from: static public void edit(java.lang.String string)
  static void edit(
    jni.JString string,
  ) {
    return _edit(string.reference).check();
  }
}

final class $FlutterWrapperType extends jni.JObjType<FlutterWrapper> {
  const $FlutterWrapperType();

  @override
  String get signature => r"Lde/yugata/easy/edits/editor/FlutterWrapper;";

  @override
  FlutterWrapper fromRef(jni.JObjectPtr ref) => FlutterWrapper.fromRef(ref);

  @override
  jni.JObjType get superType => const jni.JObjectType();

  @override
  final superCount = 1;

  @override
  int get hashCode => ($FlutterWrapperType).hashCode;

  @override
  bool operator ==(Object other) {
    return other.runtimeType == ($FlutterWrapperType) &&
        other is $FlutterWrapperType;
  }
}

/// from: de.yugata.easy.edits.editor.filter.FilterValue
class FilterValue extends jni.JObject {
  @override
  late final jni.JObjType<FilterValue> $type = type;

  FilterValue.fromRef(
    jni.JObjectPtr ref,
  ) : super.fromRef(ref);

  /// The type which includes information such as the signature of this class.
  static const type = $FilterValueType();
  static final _new0 = jniLookup<
          ffi.NativeFunction<
              jni.JniResult Function(ffi.Pointer<ffi.Void>,
                  ffi.Pointer<ffi.Void>)>>("FilterValue__new0")
      .asFunction<
          jni.JniResult Function(
              ffi.Pointer<ffi.Void>, ffi.Pointer<ffi.Void>)>();

  /// from: public void <init>(java.lang.String string, java.lang.String string1)
  /// The returned object must be released after use, by calling the [release] method.
  factory FilterValue(
    jni.JString string,
    jni.JString string1,
  ) {
    return FilterValue.fromRef(
        _new0(string.reference, string1.reference).object);
  }

  static final _getName = jniLookup<
              ffi
              .NativeFunction<jni.JniResult Function(ffi.Pointer<ffi.Void>)>>(
          "FilterValue__getName")
      .asFunction<jni.JniResult Function(ffi.Pointer<ffi.Void>)>();

  /// from: public java.lang.String getName()
  /// The returned object must be released after use, by calling the [release] method.
  jni.JString getName() {
    return const jni.JStringType().fromRef(_getName(reference).object);
  }

  static final _getValue = jniLookup<
              ffi
              .NativeFunction<jni.JniResult Function(ffi.Pointer<ffi.Void>)>>(
          "FilterValue__getValue")
      .asFunction<jni.JniResult Function(ffi.Pointer<ffi.Void>)>();

  /// from: public java.lang.String getValue()
  /// The returned object must be released after use, by calling the [release] method.
  jni.JString getValue() {
    return const jni.JStringType().fromRef(_getValue(reference).object);
  }
}

final class $FilterValueType extends jni.JObjType<FilterValue> {
  const $FilterValueType();

  @override
  String get signature => r"Lde/yugata/easy/edits/editor/filter/FilterValue;";

  @override
  FilterValue fromRef(jni.JObjectPtr ref) => FilterValue.fromRef(ref);

  @override
  jni.JObjType get superType => const jni.JObjectType();

  @override
  final superCount = 1;

  @override
  int get hashCode => ($FilterValueType).hashCode;

  @override
  bool operator ==(Object other) {
    return other.runtimeType == ($FilterValueType) && other is $FilterValueType;
  }
}

/// from: de.yugata.easy.edits.editor.filter.FilterType
class FilterType extends jni.JObject {
  @override
  late final jni.JObjType<FilterType> $type = type;

  FilterType.fromRef(
    jni.JObjectPtr ref,
  ) : super.fromRef(ref);

  /// The type which includes information such as the signature of this class.
  static const type = $FilterTypeType();
  static final _get_VIDEO =
      jniLookup<ffi.NativeFunction<jni.JniResult Function()>>(
              "get_FilterType__VIDEO")
          .asFunction<jni.JniResult Function()>();

  /// from: static public final de.yugata.easy.edits.editor.filter.FilterType VIDEO
  /// The returned object must be released after use, by calling the [release] method.
  static FilterType get VIDEO =>
      const $FilterTypeType().fromRef(_get_VIDEO().object);

  static final _get_AUDIO =
      jniLookup<ffi.NativeFunction<jni.JniResult Function()>>(
              "get_FilterType__AUDIO")
          .asFunction<jni.JniResult Function()>();

  /// from: static public final de.yugata.easy.edits.editor.filter.FilterType AUDIO
  /// The returned object must be released after use, by calling the [release] method.
  static FilterType get AUDIO =>
      const $FilterTypeType().fromRef(_get_AUDIO().object);

  static final _get_TRANSITION =
      jniLookup<ffi.NativeFunction<jni.JniResult Function()>>(
              "get_FilterType__TRANSITION")
          .asFunction<jni.JniResult Function()>();

  /// from: static public final de.yugata.easy.edits.editor.filter.FilterType TRANSITION
  /// The returned object must be released after use, by calling the [release] method.
  static FilterType get TRANSITION =>
      const $FilterTypeType().fromRef(_get_TRANSITION().object);

  static final _values =
      jniLookup<ffi.NativeFunction<jni.JniResult Function()>>(
              "FilterType__values")
          .asFunction<jni.JniResult Function()>();

  /// from: static public de.yugata.easy.edits.editor.filter.FilterType[] values()
  /// The returned object must be released after use, by calling the [release] method.
  static jni.JArray<FilterType> values() {
    return const jni.JArrayType($FilterTypeType()).fromRef(_values().object);
  }

  static final _valueOf = jniLookup<
              ffi
              .NativeFunction<jni.JniResult Function(ffi.Pointer<ffi.Void>)>>(
          "FilterType__valueOf")
      .asFunction<jni.JniResult Function(ffi.Pointer<ffi.Void>)>();

  /// from: static public de.yugata.easy.edits.editor.filter.FilterType valueOf(java.lang.String string)
  /// The returned object must be released after use, by calling the [release] method.
  static FilterType valueOf(
    jni.JString string,
  ) {
    return const $FilterTypeType().fromRef(_valueOf(string.reference).object);
  }
}

final class $FilterTypeType extends jni.JObjType<FilterType> {
  const $FilterTypeType();

  @override
  String get signature => r"Lde/yugata/easy/edits/editor/filter/FilterType;";

  @override
  FilterType fromRef(jni.JObjectPtr ref) => FilterType.fromRef(ref);

  @override
  jni.JObjType get superType => const jni.JObjectType();

  @override
  final superCount = 1;

  @override
  int get hashCode => ($FilterTypeType).hashCode;

  @override
  bool operator ==(Object other) {
    return other.runtimeType == ($FilterTypeType) && other is $FilterTypeType;
  }
}
