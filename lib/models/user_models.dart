class UserModel {
  final String? id;
  final String name;
  final String phone;
  final String email;

  UserModel({
    this.id,
    required this.name,
    required this.phone,
    required this.email,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'email': email,
      'createdAt': DateTime.now(),
    };
  }
  }
