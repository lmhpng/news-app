class NewsItem {
  final String title;
  final String link;
  final String description;
  final DateTime? pubDate;
  final String source;
  final String category;

  NewsItem({
    required this.title,
    required this.link,
    required this.description,
    required this.pubDate,
    required this.source,
    required this.category,
  });
}
