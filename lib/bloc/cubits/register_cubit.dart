import 'package:bloc/bloc.dart';
import 'package:smart_box/bloc/states/register_states.dart';
import 'package:smart_box/backend/Register_Login.dart';

class RegisterCubit extends Cubit<RegisterState> {
  RegisterCubit() : super(RegisterInitial());

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    if (password != confirmPassword) {
      emit(RegisterFailure("Passwords do not match!"));
      return;
    }

    emit(RegisterLoading());

    try {
      final result = await AuthService.register(
        name: name,
        email: email,
        password: password,
      );

      if (result["success"]) {
        emit(RegisterSuccess(result["data"]));
      } else {
        emit(RegisterFailure(result["error"]));
      }
    } catch (error) {
      emit(RegisterFailure(error.toString()));
    }
  }
}
