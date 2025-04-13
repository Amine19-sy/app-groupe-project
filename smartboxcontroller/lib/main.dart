import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_box/bloc/cubits/confirmation_cubit.dart';
import 'package:smart_box/bloc/cubits/register_cubit.dart';
import 'package:smart_box/screens/login_form.dart';
import 'package:smart_box/services/auth_service.dart';

import 'bloc/cubits/login_cubit.dart';

void main() {
  runApp( MainApp());
}

class MainApp extends StatelessWidget {
   MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => LoginCubit(authService: AuthService())), 
        BlocProvider(create: (context) => RegisterCubit(authService: AuthService())),
        BlocProvider(create: (context) => ConfirmationCubit()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home:LoginForm(),
      ),
    );
  }
}
