import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/widgets/widgets.dart';

/// A simple scrollable text page used for KVKK/privacy and the medical
/// disclaimer. Content is static prototype text.
class InfoPage extends StatelessWidget {
  const InfoPage({
    super.key,
    required this.title,
    required this.paragraphs,
  });

  final String title;
  final List<String> paragraphs;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: AppBackground(
        child: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              GlassCard(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < paragraphs.length; i++) ...[
                      Text(
                        paragraphs[i],
                        style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
                      ),
                      if (i != paragraphs.length - 1)
                        const SizedBox(height: AppSpacing.lg),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// KVKK / privacy content.
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const InfoPage(
      title: 'KVKK & Gizlilik',
      paragraphs: [
        'MiniKalp bir prototiptir. Girdiğin tüm veriler yalnızca bu cihazda, '
            'yerel olarak saklanır; herhangi bir sunucuya gönderilmez.',
        'Bebeğine ait bilgiler (ad, doğum tarihi, fotoğraflar ve kayıtlar) '
            'sadece senin erişimindedir ve uygulama silindiğinde kaldırılır.',
        '6698 sayılı Kişisel Verilerin Korunması Kanunu (KVKK) kapsamında, '
            'gerçek sürümde verilerin işlenmesi, saklanması ve silinmesine '
            'dair ayrıntılı aydınlatma metni burada yer alacaktır.',
        'Sorularınız için uygulama ayarlarından bize ulaşabilirsiniz.',
      ],
    );
  }
}

/// Medical disclaimer content.
class DisclaimerScreen extends StatelessWidget {
  const DisclaimerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const InfoPage(
      title: 'Tıbbi Sorumluluk Reddi',
      paragraphs: [
        'MiniKalp yalnızca takip ve bilgilendirme amaçlıdır; tıbbi teşhis '
            'veya tedavi aracı değildir.',
        'Uygulamadaki uyarılar ve içgörüler genel bilgilerdir ve bir '
            'sağlık profesyonelinin değerlendirmesinin yerini tutmaz.',
        'Bebeğinizin sağlığıyla ilgili her konuda ve acil durumlarda lütfen '
            'çocuk doktorunuza danışın.',
        'Bu uygulama, verdiğiniz kararlardan doğabilecek sonuçlardan sorumlu '
            'tutulamaz.',
      ],
    );
  }
}
