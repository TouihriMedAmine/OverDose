class UserModel {
  UserModel({
    required this.id,
    required this.username,
    required this.email,
    this.dateOfBirth,
    this.gender,
    this.diseases,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      dateOfBirth: json['date_of_birth'] as String?,
      gender: json['gender'] as String?,
      diseases: json['diseases'] as String?,
    );
  }

  final int id;
  final String username;
  final String email;
  final String? dateOfBirth;
  final String? gender;
  final String? diseases;
}
