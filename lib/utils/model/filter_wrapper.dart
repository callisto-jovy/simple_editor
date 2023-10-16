import 'package:video_editor/utils/easy_edits_backend.dart' as backend;

class FilterWrapper {
  final String name;
  final String description;

  Map<String, String> values;
  bool enabled;

  FilterWrapper(this.name, this.values, this.enabled, this.description);

  static FilterWrapper fromBackend(final backend.FilterWrapper wrapper) {
    final String name = wrapper.getName().toDartString(releaseOriginal: true);
    final String description = wrapper.getDescription().toDartString(releaseOriginal: true);
    final Map<String, String> values = {};

    wrapper.getValues().forEach((element) {
      values[element.getName().toDartString(releaseOriginal: true)] =
          element.getValue().toDartString(releaseOriginal: true);
    });

    return FilterWrapper(name, values, false, description);
  }

  FilterWrapper.fromJson(Map<String, dynamic> json)
      : name = json['name'],
        values = json['value'],
        description = json['description'],
        enabled = json['enabled'];

  Map<String, dynamic> toJson() =>
      {'name': name, 'values': values, 'enabled': enabled, 'description': description};
}
