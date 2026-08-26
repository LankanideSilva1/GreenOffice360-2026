class UserModel {
  final String uid;
  final String name;
  final String email;
  final String employeeId;
  final String department;
  final String role;
  final int greenScore;
  final int points;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.employeeId,
    required this.department,
    required this.role,
    this.greenScore = 0,
    this.points = 0,
  });

  factory UserModel.fromMap(
    String uid,
    Map<String, dynamic> data,
  ) {
    return UserModel(
      uid: uid,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      employeeId: data['employeeId'] ?? '',
      department: data['department'] ?? '',
      role: data['role'] ?? 'employee',
      greenScore: data['greenScore'] ?? 0,
      points: data['points'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'employeeId': employeeId,
      'department': department,
      'role': role,
      'greenScore': greenScore,
      'points': points,
    };
  }
}