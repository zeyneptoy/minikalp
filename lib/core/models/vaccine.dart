/// A vaccine in the baby's schedule (backend-backed).
class Vaccine {
  const Vaccine({
    required this.id,
    required this.name,
    required this.ageLabel,
    required this.status,
    this.dueDate,
    this.notify = false,
  });

  final int id;
  final String name;
  final String ageLabel;

  /// One of: done | upcoming | late.
  final String status;
  final DateTime? dueDate;
  final bool notify;

  factory Vaccine.fromJson(Map<String, dynamic> json) => Vaccine(
        id: (json['id'] as num).toInt(),
        name: json['name'] as String? ?? '',
        ageLabel: json['age_label'] as String? ?? '',
        status: json['status'] as String? ?? 'upcoming',
        dueDate: json['due_date'] != null
            ? DateTime.tryParse(json['due_date'] as String)
            : null,
        notify: json['notify'] as bool? ?? false,
      );
}
