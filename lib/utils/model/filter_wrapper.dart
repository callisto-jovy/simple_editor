import 'package:video_editor/utils/backend/easy_edits_backend.dart' as backend;

class FilterWrapper {
  final String name;
  final String description;
  final String help;
  final String displayName;

  final Map<String, String> values;
  bool enabled;

  // TODO: Maybe just fallback for optional attributes?
  FilterWrapper(
      {required this.name,
      required this.values,
      required this.enabled,
      required this.description,
      required this.help,
      required this.displayName});

  static FilterWrapper fromBackend(final backend.FlutterWrapper_FlutterFilterWrapper wrapper) {
    final String name = wrapper.getName().toDartString(releaseOriginal: true);
    final String description = wrapper.getDescription().toDartString(releaseOriginal: true);
    final String displayName = wrapper.getDisplayName().toDartString(releaseOriginal: true);
    final String helpText = wrapper.getHelpText().toDartString(releaseOriginal: true);

    final Map<String, String> values = {};

    wrapper.getValues().forEach((element) {
      values[element.getName().toDartString(releaseOriginal: true)] =
          element.getValue().toDartString(releaseOriginal: true);
    });

    return FilterWrapper(
        name: name,
        description: description,
        values: values,
        enabled: false,
        displayName: displayName,
        help: helpText);
  }

  /// [Map] with the saved state of that filer, only the needed attributes: id, configured values & whether it's enabled.
  Map<String, dynamic> toJson() => {'name': name, 'values': values, 'enabled': enabled};
}
