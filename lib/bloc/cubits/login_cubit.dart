import 'package:bloc/bloc.dart';
import 'package:smart_box/backend/Register_Login.dart';
import 'package:smart_box/bloc/states/login_states.dart';

class LoginCubit extends Cubit<LoginState> {
  LoginCubit() : super(LoginInitial());

  Future<void> login(String email, String password) async {
    emit(LoginLoading());
    try {
      final result = await AuthService.login(
        email: email,
        password: password,
      );

      if (result["success"]) {
        emit(LoginSuccess(result["user"]));
      } else {
        emit(LoginFailure(result["error"]));
      }
    } catch (error) {
      emit(LoginFailure(error.toString()));
    }
  }
}
