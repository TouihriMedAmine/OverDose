class HealthCondition {
  HealthCondition({required this.id, required this.label});

  factory HealthCondition.fromJson(Map<String, dynamic> json) {
    return HealthCondition(
      id: json['id'] as String,
      label: json['label'] as String,
    );
  }

  final String id;
  final String label;
}

class HealthConditionsData {
  HealthConditionsData({required this.conditions});

  factory HealthConditionsData.fromJson(Map<String, dynamic> json) {
    final list = json['conditions'] as List<dynamic>? ?? [];
    return HealthConditionsData(
      conditions: list
          .map((e) => HealthCondition.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  final List<HealthCondition> conditions;
}
