/// A doctor appointment (backend-backed).
class Appointment {
  const Appointment({
    required this.id,
    required this.title,
    this.doctor,
    this.hospital,
    this.scheduledAt,
    this.notify = false,
  });

  final int id;
  final String title;
  final String? doctor;
  final String? hospital;
  final DateTime? scheduledAt;
  final bool notify;

  factory Appointment.fromJson(Map<String, dynamic> json) => Appointment(
        id: (json['id'] as num).toInt(),
        title: json['title'] as String? ?? '',
        doctor: json['doctor'] as String?,
        hospital: json['hospital'] as String?,
        scheduledAt: json['scheduled_at'] != null
            ? DateTime.tryParse(json['scheduled_at'] as String)
            : null,
        notify: json['notify'] as bool? ?? false,
      );
}
