import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/mock/health_mock.dart' show VaccineStatus, VaccineStatusLabel;
import '../../../core/providers/health_providers.dart';
import '../../../core/providers/records_provider.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/widgets/widgets.dart';
import '../forms/fever_form.dart';

/// Sağlık segment: fever entry, mother-managed medicine/vitamin reminders,
/// vaccine schedule and doctor appointments — each addable with an optional
/// local notification.
class HealthSection extends StatelessWidget {
  const HealthSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: const [
        SectionTitle(title: 'Ateş'),
        SizedBox(height: AppSpacing.sm),
        GlassCard(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: FeverForm(),
        ),
        SizedBox(height: AppSpacing.xl),
        _MedicineBlock(),
        SizedBox(height: AppSpacing.xl),
        _VaccineBlock(),
        SizedBox(height: AppSpacing.xl),
        _AppointmentBlock(),
      ],
    );
  }
}

String _two(int n) => n.toString().padLeft(2, '0');
String _fmtDate(DateTime d) => '${d.day}.${d.month}.${d.year}';
String _fmtDateTime(DateTime d) =>
    '${d.day}.${d.month}.${d.year} · ${_two(d.hour)}:${_two(d.minute)}';

// ----- section header with an add button -----

class _BlockHeader extends StatelessWidget {
  const _BlockHeader({required this.title, required this.onAdd});
  final String title;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: SectionTitle(title: title)),
        TextButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Ekle'),
        ),
      ],
    );
  }
}

// ----- Medicine / vitamin reminders -----

class _MedicineBlock extends ConsumerWidget {
  const _MedicineBlock();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(appColorsProvider);
    final theme = Theme.of(context);
    final reminders = ref.watch(medicineRemindersProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _BlockHeader(
          title: 'İlaç / Vitamin Hatırlatıcıları',
          onAdd: () => GlassBottomSheet.show<void>(
            context,
            title: 'Hatırlatıcı ekle',
            child: const _AddMedicineForm(),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        GlassCard(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: reminders.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Text(
                    'Henüz hatırlatıcı yok. "Ekle" ile oluşturabilirsin.',
                    style: theme.textTheme.bodyMedium,
                  ),
                )
              : Column(
                  children: [
                    for (final r in reminders)
                      ListTile(
                        shape: const RoundedRectangleBorder(
                            borderRadius: AppRadius.mdAll),
                        leading: Icon(Icons.medication_rounded,
                            color: colors.primary),
                        title: Text(r.name, style: theme.textTheme.titleMedium),
                        subtitle: Text(
                          r.notify && r.remindAt != null
                              ? '${r.scheduleLabel} · 🔔 ${r.remindAt}'
                              : r.scheduleLabel,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Checkbox(
                              value: r.done,
                              onChanged: (_) => ref
                                  .read(medicineRemindersProvider.notifier)
                                  .toggle(r.id),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            IconButton(
                              onPressed: () => ref
                                  .read(medicineRemindersProvider.notifier)
                                  .remove(r.id),
                              icon: const Icon(Icons.close_rounded, size: 18),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _AddMedicineForm extends ConsumerStatefulWidget {
  const _AddMedicineForm();

  @override
  ConsumerState<_AddMedicineForm> createState() => _AddMedicineFormState();
}

class _AddMedicineFormState extends ConsumerState<_AddMedicineForm> {
  final _name = TextEditingController();
  TimeOfDay? _time;
  bool _notify = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showCupertinoTimeSheet(context, initial: _time);
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Lütfen bir isim girin.');
      return;
    }
    if (_notify && _time == null) {
      setState(() => _error = 'Bildirim için bir saat seçin.');
      return;
    }
    final remindAt =
        _time == null ? null : '${_two(_time!.hour)}:${_two(_time!.minute)}';
    final scheduleLabel = remindAt == null ? 'Her gün' : 'Her gün · $remindAt';

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await ref.read(medicineRemindersProvider.notifier).addReminder(
            name,
            scheduleLabel: scheduleLabel,
            remindAt: remindAt,
            notify: _notify,
          );
      navigator.pop();
      messenger.showSnackBar(
          const SnackBar(content: Text('Hatırlatıcı kaydedildi.')));
    } catch (_) {
      setState(() => _error = 'Kaydedilemedi. Bağlantıyı kontrol edin.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GlassTextField(
          controller: _name,
          hintText: 'Örn. D Vitamini',
          prefixIcon: Icons.medication_rounded,
          textStyle: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.md),
        _PickerRow(
          icon: Icons.schedule_rounded,
          label: 'Hatırlatma saati',
          value: _time == null
              ? 'Seç'
              : '${_two(_time!.hour)}:${_two(_time!.minute)}',
          onTap: _pickTime,
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Bu saatte bildirim gönderilsin mi?'),
          value: _notify,
          onChanged: (v) => setState(() => _notify = v),
        ),
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(_error!,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.error)),
        ],
        const SizedBox(height: AppSpacing.lg),
        PrimaryButton(label: 'Kaydet', icon: Icons.check_rounded, onPressed: _save),
      ],
    );
  }
}

// ----- Vaccines -----

class _VaccineBlock extends ConsumerWidget {
  const _VaccineBlock();

  VaccineStatus _status(String s) => switch (s) {
        'done' => VaccineStatus.done,
        'late' => VaccineStatus.late,
        _ => VaccineStatus.upcoming,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final vaccines = ref.watch(vaccinesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _BlockHeader(
          title: 'Aşı Takvimi',
          onAdd: () => GlassBottomSheet.show<void>(
            context,
            title: 'Aşı ekle',
            child: const _AddVaccineForm(),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        GlassCard(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: vaccines.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Text('Henüz aşı eklenmedi.',
                      style: theme.textTheme.bodyMedium),
                )
              : Column(
                  children: [
                    for (final v in vaccines)
                      ListTile(
                        title:
                            Text(v.name, style: theme.textTheme.titleMedium),
                        subtitle: Text(
                          v.notify && v.dueDate != null
                              ? '${v.ageLabel} · 🔔 ${_fmtDate(v.dueDate!)}'
                              : v.ageLabel,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _StatusChip(status: _status(v.status)),
                            IconButton(
                              onPressed: () =>
                                  ref.read(vaccinesProvider.notifier).remove(v.id),
                              icon: const Icon(Icons.close_rounded, size: 18),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _AddVaccineForm extends ConsumerStatefulWidget {
  const _AddVaccineForm();

  @override
  ConsumerState<_AddVaccineForm> createState() => _AddVaccineFormState();
}

class _AddVaccineFormState extends ConsumerState<_AddVaccineForm> {
  final _name = TextEditingController();
  final _age = TextEditingController();
  DateTime? _due;
  bool _notify = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _age.dispose();
    super.dispose();
  }

  Future<void> _pickDue() async {
    final now = DateTime.now();
    final picked = await showCupertinoDateSheet(
      context,
      initial: _due ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
      title: 'Aşı tarihi',
    );
    if (picked != null) setState(() => _due = picked);
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Lütfen aşı adı girin.');
      return;
    }
    if (_notify && _due == null) {
      setState(() => _error = 'Bildirim için bir tarih seçin.');
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await ref.read(vaccinesProvider.notifier).add(
            name: name,
            ageLabel: _age.text.trim().isEmpty ? '—' : _age.text.trim(),
            dueDate: _due,
            notify: _notify,
          );
      navigator.pop();
      messenger
          .showSnackBar(const SnackBar(content: Text('Aşı kaydedildi.')));
    } catch (_) {
      setState(() => _error = 'Kaydedilemedi. Bağlantıyı kontrol edin.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GlassTextField(
          controller: _name,
          hintText: 'Aşı adı (ör. KKK)',
          prefixIcon: Icons.vaccines_rounded,
          textStyle: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.md),
        GlassTextField(
          controller: _age,
          hintText: 'Dönem (ör. 12. ay)',
          prefixIcon: Icons.event_note_rounded,
          textStyle: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.md),
        _PickerRow(
          icon: Icons.event_rounded,
          label: 'Tarih',
          value: _due == null ? 'Seç' : _fmtDate(_due!),
          onTap: _pickDue,
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Bu tarih için bildirim gönderilsin mi?'),
          value: _notify,
          onChanged: (v) => setState(() => _notify = v),
        ),
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(_error!,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.error)),
        ],
        const SizedBox(height: AppSpacing.lg),
        PrimaryButton(label: 'Kaydet', icon: Icons.check_rounded, onPressed: _save),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final VaccineStatus status;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (status) {
      VaccineStatus.done => (const Color(0xFFDDF0DD), const Color(0xFF3C8C3C)),
      VaccineStatus.upcoming =>
        (const Color(0xFFE3F0FF), const Color(0xFF2F6FB3)),
      VaccineStatus.late => (const Color(0xFFFFE3DB), const Color(0xFFC2452E)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      decoration: BoxDecoration(color: bg, borderRadius: AppRadius.pillAll),
      child: Text(
        status.label,
        style: Theme.of(context)
            .textTheme
            .bodySmall
            ?.copyWith(color: fg, fontWeight: FontWeight.w700),
      ),
    );
  }
}

// ----- Doctor appointments -----

class _AppointmentBlock extends ConsumerWidget {
  const _AppointmentBlock();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(appColorsProvider);
    final theme = Theme.of(context);
    final appointments = ref.watch(appointmentsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _BlockHeader(
          title: 'Doktor Randevuları',
          onAdd: () => GlassBottomSheet.show<void>(
            context,
            title: 'Randevu ekle',
            child: const _AddAppointmentForm(),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (appointments.isEmpty)
          GlassCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text('Henüz randevu yok.',
                style: theme.textTheme.bodyMedium),
          )
        else
          for (final a in appointments)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: GlassCard(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: colors.soft,
                        borderRadius: AppRadius.mdAll,
                      ),
                      child: Icon(Icons.event_available_rounded,
                          color: colors.primary),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(a.title, style: theme.textTheme.titleMedium),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            [
                              if (a.doctor != null && a.doctor!.isNotEmpty)
                                a.doctor,
                              if (a.hospital != null && a.hospital!.isNotEmpty)
                                a.hospital,
                              if (a.scheduledAt != null)
                                _fmtDateTime(a.scheduledAt!),
                            ].join(' · '),
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    if (a.notify)
                      Icon(Icons.notifications_active_rounded,
                          color: colors.primary, size: 20),
                    IconButton(
                      onPressed: () => ref
                          .read(appointmentsProvider.notifier)
                          .remove(a.id),
                      icon: const Icon(Icons.close_rounded, size: 18),
                    ),
                  ],
                ),
              ),
            ),
      ],
    );
  }
}

class _AddAppointmentForm extends ConsumerStatefulWidget {
  const _AddAppointmentForm();

  @override
  ConsumerState<_AddAppointmentForm> createState() =>
      _AddAppointmentFormState();
}

class _AddAppointmentFormState extends ConsumerState<_AddAppointmentForm> {
  final _title = TextEditingController(text: 'Rutin kontrol');
  final _doctor = TextEditingController();
  final _hospital = TextEditingController();
  DateTime? _when;
  bool _notify = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _doctor.dispose();
    _hospital.dispose();
    super.dispose();
  }

  Future<void> _pickWhen() async {
    final now = DateTime.now();
    final picked = await showCupertinoDateTimeSheet(
      context,
      initial: _when ?? now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: DateTime(now.year + 3),
      title: 'Randevu zamanı',
    );
    if (picked != null) setState(() => _when = picked);
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty) {
      setState(() => _error = 'Lütfen bir başlık girin.');
      return;
    }
    if (_when == null) {
      setState(() => _error = 'Lütfen tarih ve saat seçin.');
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await ref.read(appointmentsProvider.notifier).add(
            title: title,
            doctor: _doctor.text.trim().isEmpty ? null : _doctor.text.trim(),
            hospital:
                _hospital.text.trim().isEmpty ? null : _hospital.text.trim(),
            scheduledAt: _when,
            notify: _notify,
          );
      navigator.pop();
      messenger
          .showSnackBar(const SnackBar(content: Text('Randevu kaydedildi.')));
    } catch (_) {
      setState(() => _error = 'Kaydedilemedi. Bağlantıyı kontrol edin.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GlassTextField(
          controller: _title,
          hintText: 'Başlık (ör. Rutin kontrol)',
          prefixIcon: Icons.medical_services_rounded,
          textStyle: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.md),
        GlassTextField(
          controller: _doctor,
          hintText: 'Doktor adı',
          prefixIcon: Icons.person_rounded,
          textStyle: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.md),
        GlassTextField(
          controller: _hospital,
          hintText: 'Hastane',
          prefixIcon: Icons.local_hospital_rounded,
          textStyle: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.md),
        _PickerRow(
          icon: Icons.event_rounded,
          label: 'Tarih ve saat',
          value: _when == null ? 'Seç' : _fmtDateTime(_when!),
          onTap: _pickWhen,
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Randevu için bildirim gönderilsin mi?'),
          value: _notify,
          onChanged: (v) => setState(() => _notify = v),
        ),
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(_error!,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.error)),
        ],
        const SizedBox(height: AppSpacing.lg),
        PrimaryButton(label: 'Kaydet', icon: Icons.check_rounded, onPressed: _save),
      ],
    );
  }
}

// ----- shared picker row -----

class _PickerRow extends ConsumerWidget {
  const _PickerRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(appColorsProvider);
    final theme = Theme.of(context);
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Icon(icon, color: colors.primary),
          const SizedBox(width: AppSpacing.md),
          Text(label, style: theme.textTheme.bodyMedium),
          const Spacer(),
          Text(value,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(width: AppSpacing.xs),
          Icon(Icons.chevron_right_rounded, color: colors.primary),
        ],
      ),
    );
  }
}
