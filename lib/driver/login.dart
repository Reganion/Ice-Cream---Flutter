import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ice_cream/auth.dart';
import 'package:ice_cream/client/landing_page.dart';
import 'package:ice_cream/driver/forgot_password.dart';
import 'package:ice_cream/driver/shipments.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  bool _isLoading = false;
  String? _emailErrorText;
  String? _passwordErrorText;

  @override
  void initState() {
    super.initState();
    _markDriverOffDutyIfOnLoginScreen();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _markDriverOffDutyIfOnLoginScreen() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('driver_token');
    if (token == null || token.isEmpty) return;

    try {
      await http.post(
        Uri.parse('${Auth.apiBaseUrl}/driver/logout'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
    } catch (_) {}

    await prefs.remove('driver_token');
    await prefs.remove('driver_profile');
    await prefs.remove('driver_password');
  }

  Future<void> _handleLogin() async {
    final email = _emailCtrl.text.trim();
    final password = _passCtrl.text.trim();

    final emailEmpty = email.isEmpty;
    final passEmpty = password.isEmpty;

    setState(() {
      if (emailEmpty && passEmpty) {
        _emailErrorText = 'This field is required.';
        _passwordErrorText = 'This field is required.';
      } else if (!emailEmpty && passEmpty) {
        _emailErrorText = null;
        _passwordErrorText = 'Please enter your password';
      } else if (emailEmpty && !passEmpty) {
        _emailErrorText = 'Please enter your email address';
        _passwordErrorText = null;
      } else {
        _emailErrorText = null;
        _passwordErrorText = null;
      }
    });

    if (emailEmpty || passEmpty) return;

    setState(() => _isLoading = true);

    try {
      final uri = Uri.parse('${Auth.apiBaseUrl}/driver/login');
      final res = await http.post(
        uri,
        headers: const {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(<String, String>{
          'email': email,
          'password': password,
        }),
      );

      Map<String, dynamic> data = <String, dynamic>{};
      try {
        data = jsonDecode(res.body) as Map<String, dynamic>;
      } catch (_) {}

      if (res.statusCode == 200 && (data['success'] == true)) {
        final token = data['token'] as String?;
        final driver = data['driver'] as Map<String, dynamic>?;

        if (token != null && token.isNotEmpty) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('driver_token', token);
          await prefs.setString('driver_password', password);
          if (driver != null) {
            await prefs.setString('driver_profile', jsonEncode(driver));
          }
        }

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const ShipmentsPage(),
          ),
        );
        return;
      }

      // Validation errors
      if (res.statusCode == 422 && data['errors'] is Map<String, dynamic>) {
        final errors = data['errors'] as Map<String, dynamic>;
        setState(() {
          final emailErrors = errors['email'];
          if (emailErrors is List && emailErrors.isNotEmpty) {
            _emailErrorText = emailErrors.first.toString();
          }
          final passErrors = errors['password'];
          if (passErrors is List && passErrors.isNotEmpty) {
            _passwordErrorText = passErrors.first.toString();
          }
        });
        return;
      }

      final msg = (data['message'] as String?) ??
          'Login failed. Please check your email and password.';
      setState(() {
        _passwordErrorText = msg;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not connect to server. Please check your connection.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _inputBgColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _inputBgColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const LandingPage()),
              (route) => false,
            );
          },
        ),
      ),
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
                      onPressed: _isLoading ? null : _handleLogin,
                      child: _isLoading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.3,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
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
