class AuthUser {
  const AuthUser({required this.id, required this.email, required this.roles});

  final int id;
  final String email;
  final Set<String> roles;

  bool hasAnyRole(Set<String> requiredRoles) =>
      roles.intersection(requiredRoles).isNotEmpty;
}
