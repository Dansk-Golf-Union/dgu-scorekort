class Player {
  final String name;
  final String memberNo;
  final double hcp;
  final String token;
  
  // OAuth-specific fields
  final String? unionId;
  final String? firstName;
  final String? lastName;
  final String? homeClubName;
  final String? homeClubId;
  final String? lifetimeId;
  final int gender; // 0 = Male, 1 = Female

  Player({
    required this.name,
    required this.memberNo,
    required this.hcp,
    this.token = '',
    this.unionId,
    this.firstName,
    this.lastName,
    this.homeClubName,
    this.homeClubId,
    this.lifetimeId,
    this.gender = 0, // Default to male
  });

  /// Factory for legacy mock data format
  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      name: json['name'] ?? json['Name'] ?? '',
      memberNo: json['memberNo'] ?? json['MemberNo'] ?? '',
      hcp: (json['hcp'] ?? json['Hcp'] ?? json['handicap'] ?? 0).toDouble(),
      token: json['token'] ?? json['Token'] ?? '',
    );
  }

  /// Factory for GolfBox API response format
  factory Player.fromGolfBoxJson(Map<String, dynamic> json) {
    // Parse handicap: "306000" → 30.6
    final handicapStr = json['Handicap'] as String? ?? '0';
    final handicapInt = int.tryParse(handicapStr) ?? 0;
    final hcp = handicapInt / 10000.0;
    
    // Parse gender: "Male" → 0, "Female" → 1
    final genderStr = json['Gender'] as String? ?? 'Male';
    final gender = genderStr.toLowerCase() == 'female' ? 1 : 0;
    
    // Get first membership (home club)
    final memberships = json['Memberships'] as List<dynamic>? ?? [];
    final homeClubMembership = memberships.isNotEmpty 
        ? memberships.first as Map<String, dynamic>
        : null;
    
    final unionId = homeClubMembership?['UnionID'] as String?;
    final homeClub = homeClubMembership?['HomeClub'] as Map<String, dynamic>?;
    
    final firstName = json['FirstName'] as String? ?? '';
    final lastName = json['LastName'] as String? ?? '';
    final fullName = '$firstName $lastName'.trim();
    
    return Player(
      name: fullName,
      memberNo: json['LifeTimeID'] as String? ?? '',
      hcp: hcp,
      token: '',
      unionId: unionId,
      firstName: firstName,
      lastName: lastName,
      homeClubName: homeClub?['Name'] as String?,
      homeClubId: homeClub?['ID'] as String?,
      lifetimeId: json['LifeTimeID'] as String?,
      gender: gender,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'memberNo': memberNo,
      'hcp': hcp,
      'token': token,
      'unionId': unionId,
      'firstName': firstName,
      'lastName': lastName,
      'homeClubName': homeClubName,
      'homeClubId': homeClubId,
      'lifetimeId': lifetimeId,
      'gender': gender,
    };
  }

  @override
  String toString() => '$name (HCP $hcp)';
}


