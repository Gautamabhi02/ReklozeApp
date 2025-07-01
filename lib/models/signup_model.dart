class SignupModel{
  final String name;
  final String email;
  final String password;

  SignupModel({required this.name, required this.email, required this.password});

  Map<String, dynamic> toJson() => {
    "userId": 0,
    "name": name,
    "email": email,
    "password": password,
    "isActive":true,
    "createdTime": DateTime.now().toIso8601String(),
  };

}
