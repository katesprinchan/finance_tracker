import 'package:finance_tracker/features/auth/data/model/auth_credentials.dart';

class AuthCredentials {
  final String jvtToken;

  const AuthCredentials(this.jvtToken);

  factory AuthCredentials.fromModel(AuthCredentialsModel model) =>
      AuthCredentials(model.jvtToken);
}
