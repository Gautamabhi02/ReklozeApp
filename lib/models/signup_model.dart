class SignupModel {
  final String userName;
  final String firstName;
  final String? middleName;
  final String lastName;
  final String email;
  final String password;

  SignupModel({
    required this.userName,
    required this.firstName,
    this.middleName,
    required this.lastName,
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
    "UserName": userName,
    "FirstName": firstName,
    "MiddleName": middleName,
    "LastName": lastName,
    "Email": email,
    "Password": password,
  };
}
