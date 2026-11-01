/// Status of a scheduled vaccine.
enum VaccineStatus { done, upcoming, late }

extension VaccineStatusLabel on VaccineStatus {
  String get label {
    switch (this) {
      case VaccineStatus.done:
        return 'Yapıldı';
      case VaccineStatus.upcoming:
        return 'Yaklaşıyor';
      case VaccineStatus.late:
        return 'Gecikti';
    }
  }
}

/// A single vaccine in the schedule list.
class VaccineItem {
  const VaccineItem({
    required this.name,
    required this.ageLabel,
    required this.status,
  });

  final String name;
  final String ageLabel;
  final VaccineStatus status;
}

/// A medicine / vitamin reminder shown in the health list.
class MedicineReminder {
  const MedicineReminder({
    required this.id,
    required this.name,
    required this.scheduleLabel,
    this.done = false,
    this.remindAt,
    this.notify = false,
  });

  final String id;
  final String name;
  final String scheduleLabel;
  final bool done;

  /// Daily reminder time as "HH:mm", or null when no notification is set.
  final String? remindAt;

  /// Whether a local notification is scheduled for this reminder.
  final bool notify;

  MedicineReminder copyWith({bool? done, String? remindAt, bool? notify}) =>
      MedicineReminder(
        id: id,
        name: name,
        scheduleLabel: scheduleLabel,
        done: done ?? this.done,
        remindAt: remindAt ?? this.remindAt,
        notify: notify ?? this.notify,
      );
}

/// A mock upcoming doctor appointment.
class DoctorAppointment {
  const DoctorAppointment({
    required this.title,
    required this.doctor,
    required this.dateLabel,
  });

  final String title;
  final String doctor;
  final String dateLabel;
}

/// Static health reference data for the prototype.
class HealthMock {
  HealthMock._();

  static const List<VaccineItem> vaccines = [
    VaccineItem(name: 'Hepatit B', ageLabel: 'Doğumda', status: VaccineStatus.done),
    VaccineItem(name: 'BCG (Verem)', ageLabel: '2. ay', status: VaccineStatus.done),
    VaccineItem(name: '5\'li Karma (DaBT-İPA-Hib)', ageLabel: '2. ay', status: VaccineStatus.done),
    VaccineItem(name: 'KPA (Pnömokok)', ageLabel: '4. ay', status: VaccineStatus.upcoming),
    VaccineItem(name: 'KKK (Kızamık)', ageLabel: '12. ay', status: VaccineStatus.late),
  ];

  static const List<MedicineReminder> medicineReminders = [
    MedicineReminder(
      id: 'd_vitamini',
      name: 'D Vitamini',
      scheduleLabel: 'Her gün · 3 damla',
      done: false,
    ),
    MedicineReminder(
      id: 'demir',
      name: 'Demir Takviyesi',
      scheduleLabel: 'Her gün · sabah',
      done: true,
    ),
  ];

  static const DoctorAppointment appointment = DoctorAppointment(
    title: 'Rutin kontrol',
    doctor: 'Dr. Elif Kaya',
    dateLabel: '12 Ekim · 10:30',
  );
}
