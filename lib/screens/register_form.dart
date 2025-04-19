import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_box/bloc/cubits/register_cubit.dart';
import 'package:smart_box/bloc/states/register_states.dart';
import 'package:smart_box/screens/homepage.dart';
import 'package:smart_box/screens/login_form.dart';
import 'package:smart_box/widgets/input_field.dart';

class RegisterForm extends StatefulWidget {
  const RegisterForm({Key? key}) : super(key: key);

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  final _registerFormKey = GlobalKey<FormState>();
  bool isAcceptTerms = false;

  // Add controllers for each field.
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Form(
                  key: _registerFormKey,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        const Text(
                          "Sign up",
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 24,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "Create an account to get started",
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 24),
                        const Text("Name", style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        CustomTextField(
                          labelText: "Name",
                          controller: _nameController,
                        ),
                        const SizedBox(height: 16),
                        const Text("Email Address", style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        CustomTextField(
                          labelText: "name@gmail.com",
                          controller: _emailController,
                        ),
                        const SizedBox(height: 16),
                        const Text("Password", style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        CustomTextField(
                          labelText: "Create a password",
                          isPassword: true,
                          controller: _passwordController,
                        ),
                        const SizedBox(height: 16),
                        const Text("Confirm password", style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        CustomTextField(
                          labelText: "Confirm password",
                          isPassword: true,
                          controller: _confirmController,
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Transform.scale(
                              scale: 1.2,
                              child: Checkbox(
                                value: isAcceptTerms,
                                onChanged: (bool? newValue) {
                                  setState(() {
                                    isAcceptTerms = newValue ?? false;
                                  });
                                },
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                side: const BorderSide(color: Colors.grey, width: 2),
                                fillColor: MaterialStateProperty.resolveWith<Color>(
                                  (states) => states.contains(MaterialState.selected) ? Colors.blue : Colors.white,
                                ),
                                checkColor: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: RichText(
                                text: TextSpan(
                                  style: const TextStyle(color: Colors.grey, fontSize: 16),
                                  children: [
                                    const TextSpan(text: "I've read and agree with the "),
                                    TextSpan(
                                      text: "Terms and Conditions",
                                      style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                                      recognizer: TapGestureRecognizer()..onTap = () {},
                                    ),
                                    const TextSpan(text: " and the "),
                                    TextSpan(
                                      text: "Privacy Policy.",
                                      style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                                      recognizer: TapGestureRecognizer()..onTap = () {},
                                    ),
                                  ],
                                ),
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 48),
                        BlocConsumer<RegisterCubit, RegisterState>(
                          listener: (context, state) {
                            if (state is RegisterSuccess) {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => HomePage(user: state.user),
                                ),
                              );
                            }
                          },
                          builder: (context, state) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (state is RegisterFailure)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 16.0),
                                    child: Text(
                                      state.error,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                SizedBox(
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed: state is RegisterLoading
                                        ? null
                                        : () {
                                            if (_registerFormKey.currentState!.validate()) {
                                              if (!isAcceptTerms) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(
                                                    content: Text("Please accept the terms and conditions"),
                                                  ),
                                                );
                                                return;
                                              }
                                              context.read<RegisterCubit>().register(
                                                    name: _nameController.text,
                                                    email: _emailController.text,
                                                    password: _passwordController.text,
                                                    confirmPassword: _confirmController.text,
                                                  );
                                            }
                                          },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: state is RegisterLoading
                                        ? const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 3,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Text(
                                            "Sign Up",
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("Already have an account? ", style: TextStyle(color: Colors.grey)),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => LoginForm(),
                                  ),
                                );                              },
                              child: const Text(
                                "Login",
                                style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                              ),
                            )
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
