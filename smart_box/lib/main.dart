import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_box/bloc/states/login_states.dart';
import 'package:smart_box/firebase_options.dart';
import 'package:smart_box/screens/homepage.dart';
import 'package:smart_box/screens/login_form.dart';
import 'package:smart_box/services/auth_service.dart';
import 'package:smart_box/services/notifications_service.dart';
import 'bloc/cubits/login_cubit.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService.instance.initialize();
  runApp(MainApp());
}

class MainApp extends StatelessWidget {
  MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final cubit = LoginCubit(authService: AuthService());

        return cubit;
      },
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: BlocBuilder<LoginCubit, LoginState>(
          builder: (context, state) {
            if (state is LoginChecking) {
              return Scaffold(body: Center(child: CircularProgressIndicator(color: Colors.black,)));
            }
            if (state is LoginSuccess) return HomePage(user: state.user);
            return LoginForm();
          },
        ),
      ),
    );
  }
}
