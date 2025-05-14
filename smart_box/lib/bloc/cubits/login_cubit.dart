import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:smart_box/services/auth_service.dart';
import 'package:smart_box/services/notifications_service.dart';
import '../states/login_states.dart';
import 'dart:async';
import 'package:flutter_native_splash/flutter_native_splash.dart';
// import '../states/login_state.dart';

class LoginCubit extends Cubit<LoginState> {
  final AuthService authService;

  LoginCubit({required this.authService}) : super(LoginChecking()) {
    _tryAutoLogin();
  }

  Future<void> _tryAutoLogin() async {
    try {
      final token = await authService.readToken();
      if (token != null) {
        final meResponse = await authService.fetchCurrentUser(token);
        emit(LoginSuccess(meResponse));
      } else {
        emit(LoginInitial());
      }
    } catch (_) {
      await authService.deleteToken();
      emit(LoginInitial());
    } finally {
      FlutterNativeSplash.remove();
    }
  }

  /// Updated method to accept username (or email) and password.
  Future<void> login(String identifier, String password) async {
    emit(LoginLoading());
    try {
      final response = await authService.login(
        username: identifier,
        password: password,
      );
      final token = response['access_token'] as String;
      // persist the JWT
      print("access token :  $token");
      await authService.persistToken(token);
      final fcmToken = await NotificationService.instance.getFcmToken();
      await authService.registerFcmToken(
        jwt: token,
        fcmToken: fcmToken!,
        deviceInfo: Platform.operatingSystem + ' ' + Platform.operatingSystemVersion,
      );
      emit(LoginSuccess(response));
    } catch (error) {
      emit(LoginFailure(error.toString()));
    }
  }
}
