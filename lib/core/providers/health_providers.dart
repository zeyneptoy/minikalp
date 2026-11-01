import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../api/api_providers.dart';
import '../models/appointment.dart';
import '../models/vaccine.dart';
import '../notifications/notification_service.dart';

// --- Vaccines ---------------------------------------------------------------

class VaccinesNotifier extends StateNotifier<List<Vaccine>> {
  VaccinesNotifier(this._ref) : super(const []) {
    _ref.listen<int?>(currentBabyIdProvider, (_, next) {
      if (next != null) _hydrate(next);
    }, fireImmediately: true);
  }

  final Ref _ref;
  ApiClient get _api => _ref.read(apiClientProvider);
  int? get _babyId => _ref.read(currentBabyIdProvider);

  Future<void> _hydrate(int babyId) async {
    try {
      final rows = await _api.listVaccines(babyId);
      state =
          rows.map((e) => Vaccine.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {/* keep local */}
  }

  Future<void> add({
    required String name,
    required String ageLabel,
    String status = 'upcoming',
    DateTime? dueDate,
    bool notify = false,
  }) async {
    final babyId = _babyId;
    if (babyId == null) {
      throw StateError('Aktif bebek profili bulunamadı.');
    }

    // Let API errors propagate so the form can surface them.
    final created = await _api.createVaccine(babyId, {
      'name': name,
      'age_label': ageLabel,
      'status': status,
      if (dueDate != null) 'due_date': dueDate.toIso8601String().substring(0, 10),
      'notify': notify,
    });
    final vaccine = Vaccine.fromJson(created);
    state = [...state, vaccine];

    if (notify && dueDate != null) {
      try {
        final granted = await NotificationService.requestPermission();
        if (granted) {
          await NotificationService.scheduleOnce(
            NotificationService.vaccineId(vaccine.id),
            DateTime(dueDate.year, dueDate.month, dueDate.day, 9),
            'Aşı hatırlatıcısı',
            '$name aşısının zamanı yaklaşıyor.',
          );
        }
      } catch (_) {/* notification is best-effort */}
    }
  }

  Future<void> remove(int id) async {
    state = state.where((v) => v.id != id).toList();
    final babyId = _babyId;
    if (babyId != null) {
      await NotificationService.cancel(NotificationService.vaccineId(id));
      _api.deleteVaccine(babyId, id).catchError((_) {});
    }
  }
}

final vaccinesProvider =
    StateNotifierProvider<VaccinesNotifier, List<Vaccine>>(
  (ref) => VaccinesNotifier(ref),
);

// --- Appointments -----------------------------------------------------------

class AppointmentsNotifier extends StateNotifier<List<Appointment>> {
  AppointmentsNotifier(this._ref) : super(const []) {
    _ref.listen<int?>(currentBabyIdProvider, (_, next) {
      if (next != null) _hydrate(next);
    }, fireImmediately: true);
  }

  final Ref _ref;
  ApiClient get _api => _ref.read(apiClientProvider);
  int? get _babyId => _ref.read(currentBabyIdProvider);

  Future<void> _hydrate(int babyId) async {
    try {
      final rows = await _api.listAppointments(babyId);
      state = rows
          .map((e) => Appointment.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {/* keep local */}
  }

  Future<void> add({
    required String title,
    String? doctor,
    String? hospital,
    DateTime? scheduledAt,
    bool notify = false,
  }) async {
    final babyId = _babyId;
    if (babyId == null) {
      throw StateError('Aktif bebek profili bulunamadı.');
    }

    final created = await _api.createAppointment(babyId, {
      'title': title,
      if (doctor != null) 'doctor': doctor,
      if (hospital != null) 'hospital': hospital,
      if (scheduledAt != null) 'scheduled_at': scheduledAt.toIso8601String(),
      'notify': notify,
    });
    final appointment = Appointment.fromJson(created);
    state = [...state, appointment]
      ..sort((a, b) => (a.scheduledAt ?? DateTime(2100))
          .compareTo(b.scheduledAt ?? DateTime(2100)));

    if (notify && scheduledAt != null) {
      try {
        final granted = await NotificationService.requestPermission();
        if (granted) {
          final remindAt = scheduledAt.subtract(const Duration(hours: 1));
          await NotificationService.scheduleOnce(
            NotificationService.appointmentId(appointment.id),
            remindAt,
            'Doktor randevusu',
            '$title yaklaşıyor${hospital != null ? ' · $hospital' : ''}.',
          );
        }
      } catch (_) {/* notification is best-effort */}
    }
  }

  Future<void> remove(int id) async {
    state = state.where((a) => a.id != id).toList();
    final babyId = _babyId;
    if (babyId != null) {
      await NotificationService.cancel(NotificationService.appointmentId(id));
      _api.deleteAppointment(babyId, id).catchError((_) {});
    }
  }
}

final appointmentsProvider =
    StateNotifierProvider<AppointmentsNotifier, List<Appointment>>(
  (ref) => AppointmentsNotifier(ref),
);
