class Player {
  final String name;
  final String memberNo;
  final double hcp;
  final String token;

  Player({
    required this.name,
    required this.memberNo,
    required this.hcp,
    this.token = '',
  });

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      name: json['name'] ?? json['Name'] ?? '',
      memberNo: json['memberNo'] ?? json['MemberNo'] ?? '',
      hcp: (json['hcp'] ?? json['Hcp'] ?? json['handicap'] ?? 0).toDouble(),
      token: json['token'] ?? json['Token'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'memberNo': memberNo,
      'hcp': hcp,
      'token': token,
    };
  }

  @override
  String toString() => '$name (HCP $hcp)';
}


