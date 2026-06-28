import 'package:bcrypt/bcrypt.dart';

void main(List<String> args) {
  final password = args.isEmpty ? 'Password@123' : args.first;
  print(BCrypt.hashpw(password, BCrypt.gensalt()));
}
