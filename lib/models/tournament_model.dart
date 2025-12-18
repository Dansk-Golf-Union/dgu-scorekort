/// Model for Golf.dk tournaments from the tournaments API
///
/// Represents a tournament with title, tour, dates, and icon.
/// Used for displaying current tournaments on the home screen.
class Tournament {
  final String tid; // Tournament ID
  final String title;
  final String tour;
  final String starts; // Start date (YYYY-MM-DD)
  final String ends; // End date (YYYY-MM-DD)
  final String icon; // Icon ID (reference to Golf.dk image)
  final String url; // URL to tournament page

  Tournament({
    required this.tid,
    required this.title,
    required this.tour,
    required this.starts,
    required this.ends,
    required this.icon,
    required this.url,
  });

  /// Parse from Golf.dk API JSON response
  ///
  /// Sample response:
  /// ```json
  /// {
  ///   "tid": "6645",
  ///   "title": "Drengene UNDER 14 ÅRS Danmarksmesterskab 2025",
  ///   "description": "DGU",
  ///   "starts": "2025-06-11",
  ///   "ends": "2025-06-13",
  ///   "icon": "6645",
  ///   "link": "https://tinyurl.com/..."
  /// }
  /// ```
  factory Tournament.fromJson(Map<String, dynamic> json) {
    return Tournament(
      tid: json['tid'] as String? ?? '',
      title: json['title'] as String? ?? 'Ingen titel',
      tour: json['description'] as String? ?? '',
      starts: json['starts'] as String? ?? '',
      ends: json['ends'] as String? ?? '',
      icon: json['icon'] as String? ?? '',
      url: json['link'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tid': tid,
      'title': title,
      'description': tour,
      'starts': starts,
      'ends': ends,
      'icon': icon,
      'link': url,
    };
  }

  @override
  String toString() {
    return 'Tournament(tid: $tid, title: $title, tour: $tour)';
  }
}

