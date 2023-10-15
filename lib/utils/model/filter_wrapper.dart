class FilterWrapper {
  final String name;
  String value;
  bool enabled;

  FilterWrapper(this.name, this.value, this.enabled);

  FilterWrapper.fromJson(Map<String, dynamic> json)
      : name = json['name'],
        value = json['value'],
        enabled = json['enabled'];

  Map<String, dynamic> toJson() => {'name': name, 'value': value, 'enabled': enabled};
}
