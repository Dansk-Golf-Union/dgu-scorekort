class ScoreHelper {
  /// Get golf term for a score relative to netto par
  static String getGolfTerm(int score, int nettoPar) {
    final diff = score - nettoPar;
    
    switch (diff) {
      case -3:
        return 'Albatros';
      case -2:
        return 'Eagle';
      case -1:
        return 'Birdie';
      case 0:
        return 'Par';
      case 1:
        return 'Bogey';
      case 2:
        return 'Double Bogey';
      default:
        return '';
    }
  }
  
  /// Get short golf term for keypad labels
  static String getShortGolfTerm(int score, int nettoPar) {
    final diff = score - nettoPar;
    
    switch (diff) {
      case -3:
        return 'Albatros';
      case -2:
        return 'Eagle';
      case -1:
        return 'Birdie';
      case 0:
        return 'Par';
      case 1:
        return 'Bogey';
      case 2:
        return '2Bogey';
      default:
        return '';
    }
  }
  
  /// Get which scores should have labels in keypad (scores around netto par)
  /// Returns map of score -> label for scores within +/- 3 of netto par
  static Map<int, String> getKeypadLabels(int nettoPar) {
    final labels = <int, String>{};
    
    // Add labels for scores from nettoPar-3 to nettoPar+2
    for (int score = nettoPar - 3; score <= nettoPar + 2; score++) {
      if (score >= 1 && score <= 9) {
        final term = getShortGolfTerm(score, nettoPar);
        if (term.isNotEmpty) {
          labels[score] = term;
        }
      }
    }
    
    return labels;
  }
  
  /// Get color for a score based on relation to netto par
  static ScoreColor getScoreColor(int score, int nettoPar) {
    final diff = score - nettoPar;
    
    if (diff < -1) return ScoreColor.excellent; // Eagle or better
    if (diff == -1) return ScoreColor.good; // Birdie
    if (diff == 0) return ScoreColor.par; // Par
    if (diff == 1) return ScoreColor.bogey; // Bogey
    return ScoreColor.poor; // Double bogey or worse
  }
}

/// Color categories for score display
enum ScoreColor {
  excellent, // Eagle or better (purple)
  good,      // Birdie (green)
  par,       // Par (blue)
  bogey,     // Bogey (orange)
  poor,      // Double bogey or worse (red)
}

