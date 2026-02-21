import 'package:flutter/material.dart';
import 'package:ice_cream/driver/forgot_password.dart';
import 'package:ice_cream/driver/shipments.dart';

// Define the shared input background for both inputs and the page.
const Color _inputBgColor = Colors.white; // <- use any matching color if needed

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'H&R Login',
      theme: ThemeData(
        scaffoldBackgroundColor: _inputBgColor,
        fontFamily: null, // uses system font like the screenshot
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: Colors.black,
          selectionColor: Color(0xFFB3D7FF),
          selectionHandleColor: Colors.black,
        ),
      ),
      home: const LoginScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  String? _emailErrorText;
  String? _passwordErrorText;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  OutlineInputBorder _border() => OutlineInputBorder(
    borderRadius: BorderRadius.circular(18),
    borderSide: const BorderSide(color: Colors.white, width: 1.2),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _inputBgColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 0),

                  // Logo (text-based, like the photo)
                  const _HRLogo(),
                  const SizedBox(height: 26),

                  // Title + subtitle
                  const Text(
                    'Welcome Rider',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1C1B1F),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Hello there, sign in to continue',
                    style: TextStyle(
                      fontSize: 15,
                      color: Color(0xFF1C1B1F),
                      fontWeight: FontWeight.w400,
                    ),
                  ),

                  const SizedBox(height: 64),

                  // Email field
                  TextField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (_) {
                      if (_emailErrorText != null)
                        setState(() => _emailErrorText = null);
                    },
                    decoration: InputDecoration(
                      hintText: 'Email Address',
                      hintStyle: const TextStyle(
                        color: Color(0xFF626262),
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                      ),
                      errorText: _emailErrorText,
                      errorStyle: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFE3001C),
                      ),
                      filled: true,
                      fillColor: _inputBgColor,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 18,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide(
                          color: _emailErrorText != null
                              ? const Color(0xFFE3001C)
                              : const Color(0xFF8C8C8C),
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide(
                          color: _emailErrorText != null
                              ? const Color(0xFFE3001C)
                              : const Color(0xFF8C8C8C),
                          width: 1,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: const BorderSide(
                          color: Color(0xFFE3001C),
                          width: 1,
                        ),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: const BorderSide(
                          color: Color(0xFFE3001C),
                          width: 1,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 26),

                  // Password field
                  TextField(
                    controller: _passCtrl,
                    obscureText: _obscure,
                    onChanged: (_) {
                      if (_passwordErrorText != null)
                        setState(() => _passwordErrorText = null);
                    },
                    decoration: InputDecoration(
                      hintText: 'Password',
                      hintStyle: const TextStyle(
                        color: Color(0xFF626262),
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                      ),
                      errorText: _passwordErrorText,
                      errorStyle: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFE3001C),
                      ),
                      filled: true,
                      fillColor: _inputBgColor,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 18,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide(
                          color: _passwordErrorText != null
                              ? const Color(0xFFE3001C)
                              : const Color(0xFF8C8C8C),
                          width: 1.2,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide(
                          color: _passwordErrorText != null
                              ? const Color(0xFFE3001C)
                              : const Color(0xFF8C8C8C),
                          width: 1.2,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: const BorderSide(
                          color: Color(0xFFE3001C),
                          width: 1.2,
                        ),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: const BorderSide(
                          color: Color(0xFFE3001C),
                          width: 1.2,
                        ),
                      ),
                      suffixIcon: Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: IconButton(
                          splashRadius: 20,
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: const Color(0xFF9B9B9B),
                            size: 22,
                          ),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 35),

                  // Login button
                  SizedBox(
                    height: 56,
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE3001B),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        shadowColor: Colors.transparent,
                      ),
                      onPressed: () {
                        final emailEmpty = _emailCtrl.text.trim().isEmpty;
                        final passEmpty = _passCtrl.text.trim().isEmpty;

                        setState(() {
                          // ✅ both empty
                          if (emailEmpty && passEmpty) {
                            _emailErrorText = 'This field is required.';
                            _passwordErrorText = 'This field is required.';
                          }
                          // ✅ email has value, password empty
                          else if (!emailEmpty && passEmpty) {
                            _emailErrorText = null;
                            _passwordErrorText = 'Please enter your password';
                          }
                          // ✅ password has value, email empty
                          else if (emailEmpty && !passEmpty) {
                            _emailErrorText = 'Please enter your email address';
                            _passwordErrorText = null;
                          }
                          // ✅ both have value
                          else {
                            _emailErrorText = null;
                            _passwordErrorText = null;
                          }
                        });

                        if (!emailEmpty && !passEmpty) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ShipmentsPage(),
                            ),
                          );
                        }
                      },

                      child: const Text(
                        'Login',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  // Forgot password
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ForgotPasswordDPage(),
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFE30000),
                      padding: const EdgeInsets.symmetric(vertical: 6),
                    ),
                    child: const Text(
                      'Forgot password?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFE3001B),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HRLogo extends StatelessWidget {
  const _HRLogo();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
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
      ],
    );
  }
}
