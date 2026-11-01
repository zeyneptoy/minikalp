/// Monthly developmental milestones (0–12 months), Turkish.
///
/// Prototype reference content only — not medical guidance.
class MilestonesMock {
  MilestonesMock._();

  static const Map<int, List<String>> byMonth = {
    0: ['Ani seslere tepki verir', 'Yüzlere odaklanır', 'Anne sesini tanır'],
    1: ['Kısa süre başını kaldırır', 'Gülümsemeye başlar', 'Elini ağzına götürür'],
    2: ['Sosyal gülümseme', 'Agulama sesleri', 'Hareketi gözle takip eder'],
    3: ['Baş kontrolü güçlenir', 'Nesneye uzanır', 'Seslere döner'],
    4: ['Yuvarlanma', 'Nesne tutma', 'Kahkaha atma'],
    5: ['Destekle oturma denemeleri', 'İsmine tepki', 'Ayaklarıyla oynama'],
    6: ['Desteksiz oturma', 'El değiştirme', 'Ek gıdaya hazır'],
    7: ['Emekleme denemeleri', 'Heceleri tekrarlar', 'Yabancı kaygısı'],
    8: ['Tutunarak ayağa kalkar', 'Çimdik kavrama', 'Cee-ee oyunu'],
    9: ['Mobilyaya tutunarak yürür', 'Basit komutları anlar', 'İşaret eder'],
    10: ['Baş baş yapar', 'Bardaktan içme denemesi', 'Nesneleri kutuya koyar'],
    11: ['Kısa süre desteksiz durur', 'İlk kelimeler', 'Karalama yapar'],
    12: ['İlk adımlar', 'Birkaç anlamlı kelime', 'Basit istekleri yapar'],
  };

  /// Milestones for the baby's current month (clamped to 0–12).
  static List<String> forMonth(int month) {
    final m = month.clamp(0, 12);
    return byMonth[m] ?? const [];
  }
}
