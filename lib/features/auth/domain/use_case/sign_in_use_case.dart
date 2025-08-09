import 'package:finance_tracker/core/domain/use_case_result/use_case_result.dart';
import 'package:finance_tracker/features/auth/domain/entity/auth_credentials.dart';
import 'package:finance_tracker/features/auth/domain/repository/auth_repository.dart';

class SignInUseCase {
  final AuthRepository _authRepo;

  SignInUseCase(this._authRepo);

  Future<UseCaseResult<AuthCredentials>> call({
    required final String email,
    required final String password,
  }) {
    return _authRepo.signIn(email: email, password: password);
  }
}
