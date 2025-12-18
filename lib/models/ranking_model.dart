/// Model for Golf.dk rankings from the rankings API
///
/// Represents a ranking list with title and icon.
/// Used for displaying current rankings on the home screen.
class Ranking {
  final String tid; // Ranking ID
  final String title;
  final String icon; // Icon ID (reference to Golf.dk image)
  final String url; // URL to ranking page

  Ranking({
    required this.tid,
    required this.title,
    required this.icon,
    required this.url,
  });

  /// Parse from Golf.dk API JSON response
  ///
  /// Sample response:
  /// ```json
  /// {
  ///   "tid": "6644",
  ///   "title": "Golf.dk Rangliste - Seneste 12 måneder",
  ///   "icon": "6644",
  ///   "link": "https://www.golf.dk/..."
  /// }
  /// ```
  factory Ranking.fromJson(Map<String, dynamic> json) {
    return Ranking(
      tid: json['tid'] as String? ?? '',
      title: json['title'] as String? ?? 'Ingen titel',
      icon: json['icon'] as String? ?? '',
      url: json['link'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tid': tid,
      'title': title,
      'icon': icon,
      'link': url,
    };
  }

  @override
  String toString() {
    return 'Ranking(tid: $tid, title: $title)';
  }
}

