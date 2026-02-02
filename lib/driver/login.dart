import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'H&R Login',
      theme: ThemeData(
        scaffoldBackgroundColor: Color(0xFFFAFAFA),
        fontFamily: null, // uses system font like the screenshot
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

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  OutlineInputBorder _border() => OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFD9D9D9), width: 1.2),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 10),

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

                  const SizedBox(height: 44),

                  // Email field
                  SizedBox(
                    height: 56,
                    child: TextField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: 'Email Address',
                        hintStyle: const TextStyle(
                          color: Color(0xFF8C8C8C),
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                        ),
                        filled: true,
                        fillColor: Color(0xFFFAFAFA),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 18,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: const BorderSide(color: Color(0xFF8C8C8C), width: 1),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: const BorderSide(color: Color(0xFF8C8C8C), width: 1),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Password field
                  SizedBox(
                    height: 56,
                    child: TextField(
                      controller: _passCtrl,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        hintText: 'Password',
                        hintStyle: const TextStyle(
                          color: Color(0xFF9B9B9B),
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 18,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: const BorderSide(color: Color(0xFF8C8C8C), width: 1.2),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: const BorderSide(color: Color(0xFF8C8C8C), width: 1.2),
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
                  ),

                  const SizedBox(height: 22),

                  // Login button
                  SizedBox(
                    height: 56,
                    width: double.infinity,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        gradient: const LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [Color(0xFFE30000), Color(0xFFFF0000)],
                        ),
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        onPressed: () {},
                        child: const Text(
                          'Login',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Forgot password
                  TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFE30000),
                      padding: const EdgeInsets.symmetric(vertical: 6),
                    ),
                    child: const Text(
                      'Forgot password?',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFE30000),
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
