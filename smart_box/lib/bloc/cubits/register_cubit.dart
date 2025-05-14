import 'dart:io';

import 'package:bloc/bloc.dart';
import 'dart:async';

import 'package:smart_box/bloc/states/register_states.dart';
import 'package:smart_box/services/auth_service.dart';
import 'package:smart_box/services/notifications_service.dart';

class RegisterCubit extends Cubit<RegisterState> {
  final AuthService authService;

  RegisterCubit({required this.authService}) : super(RegisterInitial());

  /// Updated method to accept the required fields.
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
      final response = await authService.register(
        username: name,
        email: email,
        password: password,
      );
      final token = response['access_token'] as String;
      // persist the JWT
      await authService.persistToken(token);
      final fcmToken = await NotificationService.instance.getFcmToken();
      await authService.registerFcmToken(
        jwt: token,
        fcmToken: fcmToken!,
        deviceInfo: Platform.operatingSystem + ' ' + Platform.operatingSystemVersion,
      );
      emit(RegisterSuccess(response));
    } catch (error) {
      emit(RegisterFailure(error.toString()));
    }
  }
}
