/// Model for Golf.dk news articles from the news API
///
/// Represents a news article with title, manchet (teaser), image, and URL.
/// Used for displaying latest golf news on the home screen.
class NewsArticle {
  final String title;
  final String nid; // News ID
  final String manchet; // Teaser/summary
  final String image; // Image URL
  final String url; // Article URL

  NewsArticle({
    required this.title,
    required this.nid,
    required this.manchet,
    required this.image,
    required this.url,
  });

  /// Parse from Golf.dk API JSON response
  ///
  /// Sample response:
  /// ```json
  /// {
  ///   "title": "Ekstremt gode scores i alvorlig amerikansk hyggeturnering",
  ///   "nid": "25716",
  ///   "manchet": "Winther-vejr stopper spillet på DP World Tour...",
  ///   "image": "https://drupal.golf.dk/sites/default/files/2025-12/...",
  ///   "url": "https://www.golf.dk/app/turneringer/..."
  /// }
  /// ```
  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    return NewsArticle(
      title: json['title'] as String,
      nid: json['nid'] as String,
      manchet: json['manchet'] as String,
      image: json['image'] as String,
      url: json['url'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'nid': nid,
      'manchet': manchet,
      'image': image,
      'url': url,
    };
  }

  @override
  String toString() {
    return 'NewsArticle(title: $title, nid: $nid)';
  }
}

