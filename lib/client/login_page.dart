import 'package:flutter/material.dart';
import 'package:ice_cream/auth.dart';
import 'package:ice_cream/client/forgot_password.dart';
import 'create_page.dart'; // or the correct file path
import 'home_page.dart'; // or the correct file path

enum SuffixIconType { clear, visibility }

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _obscurePassword = true;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _showEmailClear = false;
  bool _showPasswordEye = false;

  bool _emailError = false;
  bool _passwordError = false;

  // Persistent focus nodes
  final FocusNode _focusNodeEmail = FocusNode();
  final FocusNode _focusNodePassword = FocusNode();

  // Border colors
  Color _emailBorderColor = const Color(0xFFFAFAFA);
  Color _passwordBorderColor = const Color(0xFFFAFAFA);

  @override
  void initState() {
    super.initState();

    _emailController.addListener(() {
      setState(() {
        _showEmailClear = _emailController.text.isNotEmpty;
      });
    });

    _passwordController.addListener(() {
      setState(() {
        _showPasswordEye = _passwordController.text.isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _focusNodeEmail.dispose();
    _focusNodePassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 0,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Spacer(),
                      // Logo
                      Transform.translate(
                        offset: const Offset(-3, 0),
                        child: const Text(
                          'H&R',
                          style: TextStyle(
                            color: Color(0xFFE3001B),
                            fontSize: 36,
                            fontFamily: "NationalPark",
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0,
                            height: 0.9,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Transform.translate(
                        offset: const Offset(0, -3),
                        child: const Text(
                          'ICE CREAM',
                          style: TextStyle(
                            color: Color(0xFFE3001B),
                            fontSize: 16,
                            fontFamily: "NationalPark",
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 40),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Login to your Account',
                          style: TextStyle(fontSize: 16, color: Colors.black),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Email input
                      _buildInput(
                        label: "Email Address",
                        controller: _emailController,
                        errorFlag: _emailError,
                        onErrorChange: (v) => setState(() => _emailError = v),
                        borderColor: _emailBorderColor,
                        onBorderChange: (color) =>
                            setState(() => _emailBorderColor = color),
                        focusNode: _focusNodeEmail,
                        showSuffixIcon: _showEmailClear,
                        suffixIconType: SuffixIconType.clear,
                        obscureText: false,
                        onSuffixIconTap: () {
                          setState(() {
                            _emailController.clear();
                            _showEmailClear = false;
                          });
                        },
                      ),

                      const SizedBox(height: 16),

                      // Password input
                      _buildInput(
                        label: "Password",
                        controller: _passwordController,
                        errorFlag: _passwordError,
                        onErrorChange: (v) =>
                            setState(() => _passwordError = v),
                        borderColor: _passwordBorderColor,
                        onBorderChange: (color) =>
                            setState(() => _passwordBorderColor = color),
                        focusNode: _focusNodePassword,
                        showSuffixIcon: _showPasswordEye,
                        suffixIconType: SuffixIconType.visibility,
                        obscureText: _obscurePassword,
                        onSuffixIconTap: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),

                      const SizedBox(height: 1),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const ForgotPasswordPage(),
                              ),
                            );
                          },
                          child: const Text(
                            'Forgot Password?',
                            style: TextStyle(
                              color: Color(0xFFE3001C),
                              fontFamily: "NationalPark",
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 1),

                      // Login button
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: () async {
                            setState(() {
                              _emailError = _emailController.text.isEmpty;
                              _passwordError = _passwordController.text.isEmpty;
                            });

                            if (!_emailError && !_passwordError) {
                              try {
                                final result = await Auth().login(
                                  email: _emailController.text.trim(),
                                  password: _passwordController.text.trim(),
                                );

                                if (result['success'] == true) {
                                  if (!context.mounted) return;
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const HomePage(),
                                    ),
                                  );
                                  return;
                                }

                                if (result['needsOtp'] == true) {
                                  final email = result['email'] as String? ??
                                      _emailController.text.trim();
                                  if (!context.mounted) return;
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => OTPcode(
                                        email: email,
                                        password: _passwordController.text.trim(),
                                      ),
                                    ),
                                  );
                                  return;
                                }
                              } catch (e) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      e is Exception
                                          ? e.toString().replaceFirst('Exception: ', '')
                                          : 'Invalid email or password',
                                    ),
                                  ),
                                );
                              }
                            }
                          },

                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE3001C),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Login',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),
                      // Or Sign In with
                      Row(
                        children: const [
                          Expanded(child: Divider()),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8.0),
                            child: Text('Or, Sign In with'),
                          ),
                          Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: OutlinedButton(
                          onPressed: () async {
                            try {
                              final user = await Auth().signInWithGoogle();
                              if (!context.mounted) return;
                              if (user != null && user.isNotEmpty) {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const HomePage(),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Sign-in cancelled"),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    e is Exception
                                        ? e.toString().replaceFirst('Exception: ', '')
                                        : 'Google Sign-In failed',
                                  ),
                                ),
                              );
                            }
                          },

                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                'lib/client/images/CL_page/ggl.png',
                                height: 50,
                                width: 50,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Sign In with Google',
                                style: TextStyle(
                                  fontSize: 14.27,
                                  color: Colors.black,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(height: 7),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Don't have an account? "),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SignUpPage(),
                                ),
                              );
                            },
                            child: const Text(
                              'Sign up',
                              style: TextStyle(
                                color: Color(0xFFE3001C),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // --- Reusable Input Builder for LoginPage ---
  Widget _buildInput({
    required String label,
    required TextEditingController controller,
    required bool errorFlag,
    required Function(bool) onErrorChange,
    required Color borderColor,
    required Function(Color) onBorderChange,
    required FocusNode focusNode,
    bool obscureText = false,
    bool showSuffixIcon = false,
    SuffixIconType suffixIconType = SuffixIconType.visibility,
    VoidCallback? onSuffixIconTap,
  }) {
    focusNode.addListener(() {
      if (focusNode.hasFocus && !errorFlag) {
        onBorderChange(const Color(0xFF4F4F4F)); // dark gray on focus
      } else if (!focusNode.hasFocus && !errorFlag && controller.text.isEmpty) {
        onBorderChange(const Color(0xFFFAFAFA)); // light gray when unfocused
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.3),
                spreadRadius: 1,
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            obscureText: obscureText,
            style: const TextStyle(fontSize: 14),
            cursorColor: Colors.black,
            cursorHeight: 18,
            cursorWidth: 2,
            cursorRadius: const Radius.circular(3),
            onChanged: (text) {
              if (errorFlag && text.isNotEmpty) onErrorChange(false);
              onBorderChange(const Color(0xFF4F4F4F));
            },
            decoration: InputDecoration(
              labelText: label,
              labelStyle: const TextStyle(
                fontSize: 14.27,
                color: Color(0xFF727272),
              ),
              floatingLabelStyle: TextStyle(
                fontSize: 17,
                color: errorFlag
                    ? const Color(0xFFE3001C)
                    : const Color(0xFF4F4F4F),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: errorFlag ? const Color(0xFFE3001C) : borderColor,
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: errorFlag ? const Color(0xFFE3001C) : borderColor,
                  width: 1,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 16,
                horizontal: 16,
              ),
              suffixIcon: showSuffixIcon
                  ? IconButton(
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        suffixIconType == SuffixIconType.clear
                            ? Icons.close
                            : (obscureText
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined),
                        size: 22,
                      ),
                      onPressed: onSuffixIconTap,
                    )
                  : null,
            ),
          ),
        ),
        if (errorFlag)
          const Padding(
            padding: EdgeInsets.only(top: 4, left: 4),
            child: Text(
              "This field is required.",
              style: TextStyle(fontSize: 12, color: Color(0xFFE3001C)),
            ),
          ),
      ],
    );
  }
}
