class User {
  final int? id;
  final String username;
  final String? email;
  // Password is not typically stored in the User model in frontend after registration/login
  // String? password; // Only for registration or local validation if needed

  User({this.id, required this.username, this.email});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      email: json['email'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['username'] = username;
    if (email != null) {
      data['email'] = email;
    }
    // Password should be handled by the UserSerializer in Django for creation
    return data;
  }
}
