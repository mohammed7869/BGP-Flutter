class LoginRequest {
  final String itsNumber;
  final String password;

  LoginRequest({
    required this.itsNumber,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'itsNumber': itsNumber,
      'password': password,
    };
  }
}

class AuthResponse {
  final String email; // This will contain ITS number
  final String displayName;
  final String role;
  final String token;
  final bool requiresPasswordChange;

  AuthResponse({
    required this.email,
    required this.displayName,
    required this.role,
    required this.token,
    this.requiresPasswordChange = false,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      email: json['email'] as String? ?? json['Email'] as String? ?? '',
      displayName: json['displayName'] as String? ?? json['DisplayName'] as String? ?? '',
      role: json['role'] as String? ?? json['Role'] as String? ?? '',
      token: json['token'] as String? ?? json['Token'] as String? ?? '',
      requiresPasswordChange: json['requiresPasswordChange'] as bool? ?? false,
    );
  }
}

class ChangePasswordRequest {
  final String itsNumber;
  final String newPassword;
  final String confirmPassword;

  ChangePasswordRequest({
    required this.itsNumber,
    required this.newPassword,
    required this.confirmPassword,
  });

  Map<String, dynamic> toJson() {
    return {
      'itsNumber': itsNumber,
      'newPassword': newPassword,
      'confirmPassword': confirmPassword,
    };
  }
}

/// Unified login response containing all user data from users table
class UserAuthResponse {
  final int id;
  final String? profile;
  final String? itsId;
  final String fullName;
  final String email;
  final String rank;
  final int? roles;
  final String? jamiyat;
  final String? jamaat;
  final String? gender;
  final int? age;
  final String? contact;
  final String role;
  final String token;
  final bool requiresPasswordChange;

  UserAuthResponse({
    required this.id,
    this.profile,
    this.itsId,
    required this.fullName,
    required this.email,
    required this.rank,
    this.roles,
    this.jamiyat,
    this.jamaat,
    this.gender,
    this.age,
    this.contact,
    required this.role,
    required this.token,
    this.requiresPasswordChange = false,
  });

  factory UserAuthResponse.fromJson(Map<String, dynamic> json) {
    return UserAuthResponse(
      id: json['id'] as int? ?? 0,
      profile: json['profile'] as String?,
      itsId: json['itsId'] as String? ?? json['its_id'] as String?,
      fullName: json['fullName'] as String? ?? json['FullName'] as String? ?? '',
      email: json['email'] as String? ?? json['Email'] as String? ?? '',
      rank: json['rank'] as String? ?? json['Rank'] as String? ?? '',
      roles: json['roles'] as int? ?? json['Roles'] as int?,
      jamiyat: json['jamiyat'] as String? ?? json['Jamiyat'] as String?,
      jamaat: json['jamaat'] as String? ?? json['Jamaat'] as String?,
      gender: json['gender'] as String? ?? json['Gender'] as String?,
      age: json['age'] as int? ?? json['Age'] as int?,
      contact: json['contact'] as String? ?? json['Contact'] as String?,
      role: json['role'] as String? ?? json['Role'] as String? ?? '',
      token: json['token'] as String? ?? json['Token'] as String? ?? '',
      requiresPasswordChange: json['requiresPasswordChange'] as bool? ?? json['RequiresPasswordChange'] as bool? ?? false,
    );
  }

  UserData toUserData() {
    return UserData(
      id: id,
      profile: profile,
      itsId: itsId,
      fullName: fullName,
      email: email,
      rank: rank,
      roles: roles,
      jamiyat: jamiyat,
      jamaat: jamaat,
      gender: gender,
      age: age,
      contact: contact,
      role: role,
    );
  }
}

/// User data model for local storage
class UserData {
  final int id;
  final String? profile;
  final String? itsId;
  final String fullName;
  final String email;
  final String rank;
  final int? roles;
  final String? jamiyat;
  final String? jamaat;
  final String? gender;
  final int? age;
  final String? contact;
  final String role;

  UserData({
    required this.id,
    this.profile,
    this.itsId,
    required this.fullName,
    required this.email,
    required this.rank,
    this.roles,
    this.jamiyat,
    this.jamaat,
    this.gender,
    this.age,
    this.contact,
    required this.role,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'profile': profile,
      'itsId': itsId,
      'fullName': fullName,
      'email': email,
      'rank': rank,
      'roles': roles,
      'jamiyat': jamiyat,
      'jamaat': jamaat,
      'gender': gender,
      'age': age,
      'contact': contact,
      'role': role,
    };
  }

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      id: json['id'] as int? ?? 0,
      profile: json['profile'] as String?,
      itsId: json['itsId'] as String?,
      fullName: json['fullName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      rank: json['rank'] as String? ?? '',
      roles: json['roles'] as int?,
      jamiyat: json['jamiyat'] as String?,
      jamaat: json['jamaat'] as String?,
      gender: json['gender'] as String?,
      age: json['age'] as int?,
      contact: json['contact'] as String?,
      role: json['role'] as String? ?? '',
    );
  }
}

