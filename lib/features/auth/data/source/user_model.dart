class UserModel {
  final String fullName;
  final String email;
  final String profileImageURL;
  final bool isAnonymous;

  UserModel({
    required this.fullName,
    required this.email,
    required this.profileImageURL,
    this.isAnonymous = false,
  });

  Map<String, dynamic> toJson() {
    return {
      "FullName": fullName,
      "Email": email,
      "ProfileImageURL": profileImageURL,
      'isAnonymous': isAnonymous,
    };
  }
}
