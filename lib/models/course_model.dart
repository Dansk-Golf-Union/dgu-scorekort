class GolfCourse {
  final String id;
  final String name;
  final String templateID;
  final DateTime activationDate;
  final bool isActive;
  final List<Tee> tees;
  final List<Hole> holes;

  GolfCourse({
    required this.id,
    required this.name,
    required this.templateID,
    required this.activationDate,
    required this.isActive,
    required this.tees,
    required this.holes,
  });

  factory GolfCourse.fromJson(Map<String, dynamic> json) {
    // Parse ActivationDate from format "20251117T230000" to DateTime
    DateTime parseActivationDate(String dateString) {
      try {
        // Format: "20251117T230000" -> "2025-11-17T23:00:00"
        if (dateString.length >= 15) {
          final year = dateString.substring(0, 4);
          final month = dateString.substring(4, 6);
          final day = dateString.substring(6, 8);
          final hour = dateString.substring(9, 11);
          final minute = dateString.substring(11, 13);
          final second = dateString.length >= 15 ? dateString.substring(13, 15) : '00';
          final isoString = '$year-$month-${day}T$hour:$minute:$second';
          return DateTime.parse(isoString);
        }
      } catch (e) {
        // If parsing fails, return a very old date
        return DateTime(1970);
      }
      return DateTime(1970);
    }

    final activationDateString = json['ActivationDate'] ?? json['activationDate'] ?? '';
    final activationDate = activationDateString.isNotEmpty
        ? parseActivationDate(activationDateString)
        : DateTime(1970);

    // Parse Tees first, as holes might be nested in tees
    final teesList = (json['Tees'] ?? json['tees'] ?? [])
        .map((tee) => Tee.fromJson(tee))
        .toList()
        .cast<Tee>();

    // Try to get holes from multiple possible locations
    List<Hole> holesList = [];
    
    // 1. Try direct Holes array on course
    if (json['Holes'] != null || json['holes'] != null) {
      holesList = (json['Holes'] ?? json['holes'] ?? [])
          .map((hole) => Hole.fromJson(hole))
          .toList()
          .cast<Hole>();
    }
    // 2. Try to get holes from first tee if course holes are empty
    else if (teesList.isNotEmpty && teesList.first.holes != null) {
      holesList = teesList.first.holes!;
    }
    // 3. Try HoleCount/NumberOfHoles and create placeholder holes
    else {
      final holeCount = json['HoleCount'] ?? 
                       json['holeCount'] ?? 
                       json['NumberOfHoles'] ?? 
                       json['numberOfHoles'] ??
                       json['HoleNumber'] ??
                       json['holeNumber'] ??
                       0;
      if (holeCount > 0) {
        holesList = List.generate(holeCount, (index) => Hole(
          id: '',
          number: index + 1,
          par: 0,
          length: 0,
        ));
      }
    }

    return GolfCourse(
      id: json['Id'] ?? json['id'] ?? '',
      name: json['Name'] ?? json['name'] ?? '',
      templateID: json['TemplateID'] ?? json['templateID'] ?? json['TemplateId'] ?? json['templateId'] ?? '',
      activationDate: activationDate,
      isActive: json['IsActive'] ?? json['isActive'] ?? false,
      tees: teesList,
      holes: holesList,
    );
  }

  int get holeCount {
    // If we have holes, use them
    if (holes.isNotEmpty) return holes.length;
    // Otherwise, try to get hole count from any tee (if they have holes)
    for (final tee in tees) {
      if (tee.holes != null && tee.holes!.isNotEmpty) {
        return tee.holes!.length;
      }
    }
    // If still no holes found, return 0
    return 0;
  }

  // Find the longest men's tee (Gender 0)
  Tee? get longestMenTee {
    final menTees = tees.where((tee) => tee.gender == 0).toList();
    if (menTees.isEmpty) return null;
    
    menTees.sort((a, b) => b.totalLength.compareTo(a.totalLength));
    return menTees.first;
  }
}

class Tee {
  final String id;
  final String name;
  final int gender; // 0 = Herre, 1 = Dame
  final double courseRating; // Parsed from string and divided by 10000
  final int slopeRating;
  final int totalLength;
  final bool isNineHole; // Indicates if this is a 9-hole tee
  final List<Hole>? holes; // Holes might be nested in Tee

  Tee({
    required this.id,
    required this.name,
    required this.gender,
    required this.courseRating,
    required this.slopeRating,
    required this.totalLength,
    this.isNineHole = false,
    this.holes,
  });

  factory Tee.fromJson(Map<String, dynamic> json) {
    // Parse CourseRating from string (e.g., "719000") to double (71.9)
    final courseRatingString = json['CourseRating'] ?? json['courseRating'] ?? '0';
    final courseRatingValue = double.tryParse(courseRatingString) ?? 0.0;
    final courseRating = courseRatingValue / 10000;

    // Try to parse holes if they exist in the tee
    List<Hole>? holesList;
    if (json['Holes'] != null || json['holes'] != null) {
      holesList = (json['Holes'] ?? json['holes'] ?? [])
          .map((hole) => Hole.fromJson(hole))
          .toList()
          .cast<Hole>();
    }

    return Tee(
      id: json['Id'] ?? json['id'] ?? '',
      name: json['Name'] ?? json['name'] ?? '',
      gender: json['Gender'] ?? json['gender'] ?? 0,
      courseRating: courseRating,
      slopeRating: json['SlopeRating'] ?? json['slopeRating'] ?? 0,
      totalLength: json['TotalLength'] ?? json['totalLength'] ?? 0,
      isNineHole: json['IsNineHole'] ?? json['isNineHole'] ?? false,
      holes: holesList?.isEmpty ?? true ? null : holesList,
    );
  }

  String get genderLabel => gender == 0 ? 'Herre' : 'Dame';
}

class Hole {
  final String id;
  final int number;
  final int par;
  final int length;
  final int index; // Handicap index (1-18) - difficulty order

  Hole({
    required this.id,
    required this.number,
    required this.par,
    required this.length,
    int? index,
  }) : index = index ?? number; // Default to hole number if index not provided

  factory Hole.fromJson(Map<String, dynamic> json) {
    return Hole(
      id: json['Id'] ?? json['id'] ?? '',
      number: json['Number'] ?? json['number'] ?? 0,
      par: json['Par'] ?? json['par'] ?? 0,
      length: json['Length'] ?? json['length'] ?? 0,
      index: json['Index'] ?? json['index'] ?? json['HcpIndex'] ?? json['hcpIndex'],
    );
  }
}


