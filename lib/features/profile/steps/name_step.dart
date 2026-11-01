import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/profile_provider.dart';
import '../../../core/widgets/widgets.dart';
import '../widgets/step_layout.dart';

/// Step 1 — the baby's name, entered in a large glass text field.
class NameStep extends ConsumerStatefulWidget {
  const NameStep({super.key});

  @override
  ConsumerState<NameStep> createState() => _NameStepState();
}

class _NameStepState extends ConsumerState<NameStep> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    // Seed from any existing draft value (edit flow / returning to the step).
    _controller = TextEditingController(text: ref.read(profileDraftProvider).name);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StepLayout(
      title: 'Bebeğinizin adı nedir?',
      subtitle: 'Uygulamayı kişiselleştirmek için adını kullanacağız.',
      child: GlassTextField(
        controller: _controller,
        hintText: 'Örn. Defne',
        prefixIcon: Icons.child_care_rounded,
        autofocus: true,
        onChanged: (value) =>
            ref.read(profileDraftProvider.notifier).setName(value),
        onSubmitted: (value) =>
            ref.read(profileDraftProvider.notifier).setName(value),
      ),
    );
  }
}
