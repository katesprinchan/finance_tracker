import 'package:finance_tracker/core/data/remote_response.dart';
import 'package:finance_tracker/features/auth/data/model/auth_credentials.dart';

abstract interface class AuthDataSource {
  Future<RemoteResponse<AuthCredentialsModel>> signIn({
    required final String email,
    required final String password,
  });

  Future<RemoteResponse<AuthCredentialsModel>> signUp({
    required final String password,
    required String repeatPassword,
  });

  Future<RemoteResponse<AuthCredentialsModel>> recoveryPassword({
    required final String email,
  });

  Future<RemoteResponse<AuthCredentialsModel>> enterCode({
    required final String number1,
    required final String number2,
    required final String number3,
    required final String number4,
  });
}
