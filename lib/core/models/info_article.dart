/// A general informational article shown on the home screen.
class InfoArticle {
  const InfoArticle({
    required this.id,
    required this.title,
    required this.excerpt,
    required this.body,
    this.imageUrl,
  });

  final int id;
  final String title;
  final String excerpt;
  final String body;
  final String? imageUrl;

  factory InfoArticle.fromJson(Map<String, dynamic> json) => InfoArticle(
        id: (json['id'] as num).toInt(),
        title: json['title'] as String? ?? '',
        excerpt: json['excerpt'] as String? ?? '',
        body: json['body'] as String? ?? '',
        imageUrl: json['image_url'] as String?,
      );
}
