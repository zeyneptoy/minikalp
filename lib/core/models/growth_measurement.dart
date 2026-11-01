/// A single growth measurement (weight/height/head) at a point in time.
class GrowthMeasurement {
  const GrowthMeasurement({
    required this.id,
    required this.weightKg,
    required this.heightCm,
    required this.headCm,
    required this.measuredAt,
  });

  final int id;
  final double? weightKg;
  final double? heightCm;
  final double? headCm;
  final DateTime measuredAt;

  factory GrowthMeasurement.fromJson(Map<String, dynamic> json) =>
      GrowthMeasurement(
        id: (json['id'] as num).toInt(),
        weightKg: (json['weight_kg'] as num?)?.toDouble(),
        heightCm: (json['height_cm'] as num?)?.toDouble(),
        headCm: (json['head_cm'] as num?)?.toDouble(),
        measuredAt: DateTime.tryParse(json['measured_at'] as String? ?? '') ??
            DateTime.now(),
      );
}
