import 'package:bcrypt/bcrypt.dart';

class PasswordHash {
  static String create(String password) =>
      BCrypt.hashpw(password, BCrypt.gensalt());

  static bool verify(String password, String hash) =>
      BCrypt.checkpw(password, hash);
}
