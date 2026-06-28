import '../common/app_constants.dart';

class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.roles,
  });

  final int id;
  final String name;
  final String email;
  final List<String> roles;

  bool hasRole(String role) => roles.contains(role);

  String get primaryRole {
    if (hasRole(AppRoles.admin)) return AppRoles.admin;
    if (hasRole(AppRoles.merchant)) return AppRoles.merchant;
    return AppRoles.buyer;
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as int,
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      roles: (json['roles'] as List? ?? const [])
          .map((role) => role.toString())
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'roles': roles,
  };
}
