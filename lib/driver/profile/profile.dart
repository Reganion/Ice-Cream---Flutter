import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ice_cream/auth.dart';
import 'package:ice_cream/driver/login.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _loading = true;
  int _totalDelivered = 0;
  Map<String, dynamic> _driver = <String, dynamic>{};
  String _storedPassword = '';

  String get _name => (_driver['name'] ?? '').toString().trim();
  String get _phone => (_driver['phone'] ?? '').toString().trim();
  String get _email => (_driver['email'] ?? '').toString().trim();
  String get _password {
    final fromDriver = (_driver['password'] ?? '').toString();
    if (fromDriver.isNotEmpty) return fromDriver;
    return _storedPassword;
  }
  String get _licenseNo => (_driver['license_no'] ?? '').toString().trim();
  String get _licenseType => (_driver['license_type'] ?? '').toString().trim();
  String? get _imageUrl {
    final v = _driver['image_url'] ?? _driver['image'];
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  Future<void> _saveDriverProfileCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('driver_profile', jsonEncode(_driver));
  }

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('driver_token');
      final cached = prefs.getString('driver_profile');
      _storedPassword = prefs.getString('driver_password') ?? '';

      if (cached != null && cached.isNotEmpty) {
        try {
          final map = jsonDecode(cached) as Map<String, dynamic>;
          if ((map['password'] ?? '').toString().isEmpty &&
              _storedPassword.isNotEmpty) {
            map['password'] = _storedPassword;
          }
          if (mounted) setState(() => _driver = map);
        } catch (_) {}
      }

      if (token == null || token.isEmpty) {
        if (mounted) setState(() => _loading = false);
        return;
      }

      final responses = await Future.wait([
        http.get(
          Uri.parse('${Auth.apiBaseUrl}/driver/me'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
        http.get(
          Uri.parse('${Auth.apiBaseUrl}/driver/shipments').replace(
            queryParameters: {'tab': 'completed'},
          ),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      ]);

      final meRes = responses[0];
      final completedRes = responses[1];
      if (!mounted) return;

      if (meRes.statusCode == 200) {
        final meData = jsonDecode(meRes.body) as Map<String, dynamic>;
        final driver = meData['driver'];
        if (driver is Map<String, dynamic>) {
          if ((driver['password'] ?? '').toString().isEmpty &&
              _storedPassword.isNotEmpty) {
            driver['password'] = _storedPassword;
          }
          _driver = driver;
          await prefs.setString('driver_profile', jsonEncode(driver));
        }
      }

      if (completedRes.statusCode == 200) {
        final shipData = jsonDecode(completedRes.body) as Map<String, dynamic>;
        final count = shipData['count'];
        _totalDelivered = count is num ? count.toInt() : 0;
      }

      setState(() => _loading = false);
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('driver_token');
    if (token != null && token.isNotEmpty) {
      try {
        await http.post(
          Uri.parse('${Auth.apiBaseUrl}/driver/logout'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
      } catch (_) {}
    }
    await prefs.remove('driver_token');
    await prefs.remove('driver_profile');
    await prefs.remove('driver_password');
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    const red = Color(0xFFE3001B);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // HEADER (red with big rounded bottom)
            SizedBox(
              height: 180,
              child: Stack(
                children: [
                  // red background
                  Positioned.fill(
                    child: Container(
                      decoration: const BoxDecoration(
                        color: red,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(48),
                          bottomRight: Radius.circular(48),
                        ),
                      ),
                    ),
                  ),

                  // top row: back + title
                  Positioned(
                    left: 14,
                    top: 14,
                    right: 14,
                    child: Row(
                      children: [
                        InkWell(
                          onTap: () => Navigator.pop(context),
                          borderRadius: BorderRadius.circular(999),
                          child: const SizedBox(
                            width: 40,
                            height: 40,
                            child: Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 22,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          "Profile",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // avatar
                  Positioned(
                    left: 22,
                    top: 83,
                    child: Container(
                      width: 69,
                      height: 69,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFFFE0E0),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _imageUrl != null && _imageUrl!.startsWith('http')
                          ? Image.network(
                              _imageUrl!,
                              width: 69,
                              height: 69,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const SizedBox(
                                  width: 69,
                                  height: 69,
                                  child: Icon(
                                    Icons.person,
                                    size: 32,
                                    color: Color(0xFFE30613),
                                  ),
                                );
                              },
                            )
                          : Image.asset(
                              "lib/driver/profile/images/kyley.png",
                              width: 69,
                              height: 69,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const SizedBox(
                                  width: 69,
                                  height: 69,
                                  child: Icon(
                                    Icons.person,
                                    size: 32,
                                    color: Color(0xFFE30613),
                                  ),
                                );
                              },
                            ),
                    ),
                  ),

                  // name + phone
                  Positioned(
                    left: 110,
                    top: 90,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _name.isNotEmpty ? _name : "H&R Driver",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _phone.isNotEmpty ? _phone : "—",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // BODY
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                children: [
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: LinearProgressIndicator(
                        minHeight: 3,
                        color: red,
                        backgroundColor: Color(0xFFF2F2F2),
                      ),
                    ),
                  // stats row – one card with divider in the middle
                  Container(
                    height: 82,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFEFEFEF)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          spreadRadius: 0,
                          offset: const Offset(0, 0.5),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(height: 4),
                                const Text(
                                  "Total Delivered",
                                  style: TextStyle(
                                    color: Color(0xFF8B8B8B),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "$_totalDelivered",
                                  style: TextStyle(
                                    color: red,
                                    fontSize: 19,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Container(
                            width: 1,
                            color: const Color(0xFFE5E5E5),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(height: 4),
                                const Text(
                                  "Total Login Hrs",
                                  style: TextStyle(
                                    color: Color(0xFF8B8B8B),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "--",
                                  style: TextStyle(
                                    color: red,
                                    fontSize: 19,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // details card
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFEFEFEF)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          spreadRadius: 0,
                          offset: const Offset(0, 0.5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _InfoRow(
                          label: "Phone Number",
                          value: _phone.isNotEmpty ? _phone : "—",
                          trailingText: "Change",
                          showDivider: true,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (context) => EditPhoneNumberPage(
                                  initialPhone: _phone,
                                ),
                              ),
                            );
                          },
                        ),
                        _InfoRow(
                          label: "Email",
                          value: _email.isNotEmpty ? _email : "—",
                          trailingText: "Change",
                          showDivider: true,
                          onTap: () async {
                            final updatedEmail = await Navigator.push<String>(
                              context,
                              MaterialPageRoute<String>(
                                builder: (context) => EditEmailAddressPage(
                                  initialEmail: _email,
                                ),
                              ),
                            );
                            if (updatedEmail == null ||
                                updatedEmail.trim().isEmpty) {
                              return;
                            }
                            if (!mounted) return;
                            setState(() {
                              _driver['email'] = updatedEmail.trim();
                            });
                            await _saveDriverProfileCache();
                          },
                        ),
                        _InfoRow(
                          label: "Password",
                          value: _password.isNotEmpty ? "••••••••" : "—",
                          trailingText: "Change",
                          showDivider: true,
                          onTap: () async {
                            final updatedPassword = await Navigator.push<String>(
                              context,
                              MaterialPageRoute<String>(
                                builder: (context) => EditPasswordPage(
                                  initialPassword: _password,
                                  currentEmail: _email,
                                ),
                              ),
                            );

                            if (updatedPassword == null ||
                                updatedPassword.trim().isEmpty) {
                              return;
                            }

                            final trimmed = updatedPassword.trim();
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setString('driver_password', trimmed);
                            if (!mounted) return;
                            setState(() {
                              _storedPassword = trimmed;
                              _driver['password'] = trimmed;
                            });
                            await _saveDriverProfileCache();
                          },
                        ),
                        _InfoRow(
                          label: "License No:",
                          value: _licenseNo.isNotEmpty ? _licenseNo : "—",
                          trailingText: null,
                          showDivider: true,
                        ),
                        _InfoRow(
                          label: "License Type:",
                          value: _licenseType.isNotEmpty ? _licenseType : "—",
                          trailingText: null,
                          showDivider: false,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 111),
                

                  // logout button (outlined pill)
                  SizedBox(
                    height: 56,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: red, width: 1),
                        shape: const StadiumBorder(),
                        foregroundColor: red,
                        backgroundColor: Colors.white,
                      ),
                      onPressed: () {
                        _logout();
                      },
                      child: const Text(
                        "Log out",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Edit phone number screen matching the design: title, subtitle, input, Update button.
class EditPhoneNumberPage extends StatefulWidget {
  final String initialPhone;

  const EditPhoneNumberPage({super.key, this.initialPhone = ''});

  @override
  State<EditPhoneNumberPage> createState() => _EditPhoneNumberPageState();
}

class _EditPhoneNumberPageState extends State<EditPhoneNumberPage> {
  late final TextEditingController _controller;
  late final VoidCallback _listener;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialPhone);
    _listener = () => setState(() {});
    _controller.addListener(_listener);
  }

  @override
  void dispose() {
    _controller.removeListener(_listener);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const defaultPink = Color(0xFFFF9CA7);
    const activeRed = Color(0xFFE3001B);
    final hasValue = _controller.text.trim().isNotEmpty;
    final buttonColor = hasValue ? activeRed : defaultPink;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    width: 43,
                    height: 43,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFF2F2F2),
                     
                   
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.close, size: 20, color: Color(0xFF414141)),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Edit phone number',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1C1B1F),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Keep your phone number up to date.',
                style: TextStyle(
                  fontSize: 15,
                  color: Color(0xFF747474),
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: 'Phone number',
                  hintStyle: const TextStyle(
                    color: Color(0xFF696969),
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF8C8C8C)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF8C8C8C)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF8C8C8C), width: 1.2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                ),
                style: const TextStyle(fontSize: 16, color: Color(0xFF1C1B1F)),
                keyboardType: TextInputType.phone,
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (!hasValue) return;
                    showSuccessDialog(context);
                    Future.delayed(const Duration(seconds: 3), () {
                      if (!context.mounted) return;
                      Navigator.pop(context); // close dialog
                      Navigator.pop(context); // back to ProfilePage
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Update',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}

/// Edit email address screen: same layout as Edit phone number.
class EditEmailAddressPage extends StatefulWidget {
  final String initialEmail;

  const EditEmailAddressPage({super.key, this.initialEmail = ''});

  @override
  State<EditEmailAddressPage> createState() => _EditEmailAddressPageState();
}

class _EditEmailAddressPageState extends State<EditEmailAddressPage> {
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final VoidCallback _listener;
  bool _sending = false;
  bool _obscurePassword = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail);
    _passwordController = TextEditingController();
    _listener = () => setState(() {});
    _emailController.addListener(_listener);
    _passwordController.addListener(_listener);
  }

  @override
  void dispose() {
    _emailController.removeListener(_listener);
    _passwordController.removeListener(_listener);
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool get _canSubmit {
    return _emailController.text.trim().isNotEmpty &&
        _passwordController.text.trim().isNotEmpty &&
        !_sending;
  }

  Future<void> _sendOtp() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('driver_token') ?? '';
    if (token.isEmpty) {
      throw Exception('Not authenticated. Please login again.');
    }

    final response = await http.post(
      Uri.parse('${Auth.apiBaseUrl}/driver/change-email/send-otp'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'current_password': _passwordController.text.trim(),
        'new_email': _emailController.text.trim(),
      }),
    );

    final data = _safeDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) return;
    throw Exception(_extractApiMessage(data));
  }

  @override
  Widget build(BuildContext context) {
    const defaultPink = Color(0xFFFF9CA7);
    const activeRed = Color(0xFFE3001B);
    final buttonColor = _canSubmit ? activeRed : defaultPink;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    width: 43,
                    height: 43,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFF2F2F2),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.close, size: 20, color: Color(0xFF414141)),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Edit email address',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1C1B1F),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Enter current password then verify OTP sent to your new email.',
                style: TextStyle(
                  fontSize: 15,
                  color: Color(0xFF747474),
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 28),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: 'Current password',
                  hintStyle: const TextStyle(
                    color: Color(0xFF696969),
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                  ),
                  suffixIcon: IconButton(
                    onPressed: () => setState(
                      () => _obscurePassword = !_obscurePassword,
                    ),
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      size: 20,
                      color: const Color(0xFF777777),
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF8C8C8C)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF8C8C8C)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF8C8C8C), width: 1.2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                ),
                style: const TextStyle(fontSize: 16, color: Color(0xFF1C1B1F)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  hintText: 'New email',
                  hintStyle: const TextStyle(
                    color: Color(0xFF696969),
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF8C8C8C)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF8C8C8C)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF8C8C8C), width: 1.2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                ),
                style: const TextStyle(fontSize: 16, color: Color(0xFF1C1B1F)),
                keyboardType: TextInputType.emailAddress,
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 13,
                    ),
                  ),
                ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _canSubmit
                      ? () async {
                          setState(() {
                            _sending = true;
                            _error = null;
                          });
                          try {
                            await _sendOtp();
                            if (!mounted) return;
                            final updatedEmail = await Navigator.push<String>(
                              context,
                              MaterialPageRoute<String>(
                                builder: (_) => DriverEmailOtpPage(
                                  pendingEmail: _emailController.text.trim(),
                                ),
                              ),
                            );
                            if (!mounted) return;
                            if (updatedEmail != null && updatedEmail.trim().isNotEmpty) {
                              Navigator.pop(context, updatedEmail.trim());
                            }
                          } catch (e) {
                            if (!mounted) return;
                            setState(() {
                              _error = e.toString().replaceFirst('Exception: ', '');
                            });
                          } finally {
                            if (mounted) setState(() => _sending = false);
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    _sending ? 'Sending OTP...' : 'Update',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}

/// Edit password screen: same layout as other edit screens.
class EditPasswordPage extends StatefulWidget {
  final String initialPassword;
  final String currentEmail;

  const EditPasswordPage({
    super.key,
    this.initialPassword = '',
    this.currentEmail = '',
  });

  @override
  State<EditPasswordPage> createState() => _EditPasswordPageState();
}

class _EditPasswordPageState extends State<EditPasswordPage> {
  late final TextEditingController _currentPasswordController;
  late final TextEditingController _newPasswordController;
  late final TextEditingController _retypePasswordController;
  late final VoidCallback _listener;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureRetype = true;
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _currentPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _retypePasswordController = TextEditingController();
    _listener = () => setState(() {});
    _currentPasswordController.addListener(_listener);
    _newPasswordController.addListener(_listener);
    _retypePasswordController.addListener(_listener);
  }

  @override
  void dispose() {
    _currentPasswordController.removeListener(_listener);
    _newPasswordController.removeListener(_listener);
    _retypePasswordController.removeListener(_listener);
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _retypePasswordController.dispose();
    super.dispose();
  }

  bool get _canSubmit {
    return _currentPasswordController.text.trim().isNotEmpty &&
        _newPasswordController.text.trim().isNotEmpty &&
        _retypePasswordController.text.trim().isNotEmpty &&
        !_sending;
  }

  Future<void> _sendOtp() async {
    final currentPassword = _currentPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final retypePassword = _retypePasswordController.text.trim();
    if (newPassword != retypePassword) {
      throw Exception('New password and retype password do not match.');
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('driver_token') ?? '';
    if (token.isEmpty) {
      throw Exception('Not authenticated. Please login again.');
    }

    final response = await http.post(
      Uri.parse('${Auth.apiBaseUrl}/driver/change-password/send-otp'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'current_password': currentPassword,
        'new_password': newPassword,
        'new_password_confirmation': retypePassword,
      }),
    );
    final data = _safeDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) return;
    throw Exception(_extractApiMessage(data));
  }

  @override
  Widget build(BuildContext context) {
    const defaultPink = Color(0xFFFF9CA7);
    const activeRed = Color(0xFFE3001B);
    final buttonColor = _canSubmit ? activeRed : defaultPink;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    width: 43,
                    height: 43,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFF2F2F2),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.close, size: 20, color: Color(0xFF414141)),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Change password',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1C1B1F),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Enter current, new, retype password then verify OTP in email.',
                style: TextStyle(
                  fontSize: 15,
                  color: Color(0xFF747474),
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 28),
              _passwordField(
                controller: _currentPasswordController,
                hintText: 'Current password',
                obscureText: _obscureCurrent,
                onToggle: () => setState(() => _obscureCurrent = !_obscureCurrent),
              ),
              const SizedBox(height: 12),
              _passwordField(
                controller: _newPasswordController,
                hintText: 'New password',
                obscureText: _obscureNew,
                onToggle: () => setState(() => _obscureNew = !_obscureNew),
              ),
              const SizedBox(height: 12),
              _passwordField(
                controller: _retypePasswordController,
                hintText: 'Retype password',
                obscureText: _obscureRetype,
                onToggle: () => setState(() => _obscureRetype = !_obscureRetype),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 13,
                    ),
                  ),
                ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _canSubmit
                      ? () async {
                          setState(() {
                            _sending = true;
                            _error = null;
                          });
                          try {
                            await _sendOtp();
                            if (!mounted) return;
                            final ok = await Navigator.push<bool>(
                              context,
                              MaterialPageRoute<bool>(
                                builder: (_) => DriverPasswordOtpPage(
                                  email: widget.currentEmail,
                                ),
                              ),
                            );
                            if (!mounted) return;
                            if (ok == true) {
                              Navigator.pop(context, _newPasswordController.text.trim());
                            }
                          } catch (e) {
                            if (!mounted) return;
                            setState(() {
                              _error = e.toString().replaceFirst('Exception: ', '');
                            });
                          } finally {
                            if (mounted) setState(() => _sending = false);
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    _sending ? 'Sending OTP...' : 'Update',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _passwordField({
    required TextEditingController controller,
    required String hintText,
    required bool obscureText,
    required VoidCallback onToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          color: Color(0xFF696969),
          fontSize: 15,
          fontWeight: FontWeight.w400,
        ),
        suffixIcon: IconButton(
          onPressed: onToggle,
          icon: Icon(
            obscureText ? Icons.visibility_off : Icons.visibility,
            size: 20,
            color: const Color(0xFF777777),
          ),
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF8C8C8C)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF8C8C8C)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF8C8C8C), width: 1.2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      ),
      style: const TextStyle(fontSize: 16, color: Color(0xFF1C1B1F)),
    );
  }
}

class DriverEmailOtpPage extends StatefulWidget {
  final String pendingEmail;

  const DriverEmailOtpPage({super.key, required this.pendingEmail});

  @override
  State<DriverEmailOtpPage> createState() => _DriverEmailOtpPageState();
}

class _DriverEmailOtpPageState extends State<DriverEmailOtpPage> {
  final List<String> _otp = ["", "", "", ""];
  bool _loading = false;
  String? _error;

  bool get _isFilled => _otp.every((v) => v.isNotEmpty);

  Future<void> _verifyOtp() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('driver_token') ?? '';
    if (token.isEmpty) throw Exception('Not authenticated. Please login again.');

    final response = await http.post(
      Uri.parse('${Auth.apiBaseUrl}/driver/change-email/verify-otp'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'otp': _otp.join()}),
    );

    final data = _safeDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      final driver = data['driver'];
      if (driver is Map<String, dynamic>) {
        await prefs.setString('driver_profile', jsonEncode(driver));
      }
      return;
    }
    throw Exception(_extractApiMessage(data));
  }

  Future<void> _resendOtp() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('driver_token') ?? '';
    if (token.isEmpty) throw Exception('Not authenticated. Please login again.');

    final response = await http.post(
      Uri.parse('${Auth.apiBaseUrl}/driver/change-email/resend-otp'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    final data = _safeDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) return;
    throw Exception(_extractApiMessage(data));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    width: 43,
                    height: 43,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF2F2F2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back, color: Colors.black, size: 20),
                  ),
                ),
              ),
              const SizedBox(height: 120),
              const Text(
                "Enter OTP Code",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1C1C1C),
                ),
              ),
              const SizedBox(height: 8),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  text: "We sent code to ",
                  style: const TextStyle(fontSize: 15, color: Color(0xFF505050)),
                  children: [
                    TextSpan(
                      text: widget.pendingEmail,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF1C1B1F),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 50),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  4,
                  (index) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: _OtpInput(
                      index: index,
                      onChanged: (value) {
                        setState(() => _otp[index] = value);
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: (_isFilled && !_loading)
                      ? () async {
                          setState(() {
                            _loading = true;
                            _error = null;
                          });
                          try {
                            await _verifyOtp();
                            if (!mounted) return;
                            Navigator.pop(context, widget.pendingEmail);
                          } catch (e) {
                            if (!mounted) return;
                            setState(() {
                              _error = e.toString().replaceFirst('Exception: ', '');
                            });
                          } finally {
                            if (mounted) setState(() => _loading = false);
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        (_isFilled && !_loading) ? const Color(0xFFE3001B) : const Color(0xFFFF9CA7),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    elevation: 0,
                  ),
                  child: Text(_loading ? "Verifying..." : "Continue"),
                ),
              ),
              const SizedBox(height: 35),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Didn’t get OTP? ", style: TextStyle(fontSize: 14.85)),
                  GestureDetector(
                    onTap: _loading
                        ? null
                        : () async {
                            try {
                              await _resendOtp();
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('A new OTP has been sent.')),
                              );
                            } catch (e) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
                              );
                            }
                          },
                    child: const Text(
                      "Resend OTP",
                      style: TextStyle(
                        fontSize: 15,
                        color: Color(0xFFE3001B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DriverPasswordOtpPage extends StatefulWidget {
  final String email;

  const DriverPasswordOtpPage({super.key, required this.email});

  @override
  State<DriverPasswordOtpPage> createState() => _DriverPasswordOtpPageState();
}

class _DriverPasswordOtpPageState extends State<DriverPasswordOtpPage> {
  final List<String> _otp = ["", "", "", ""];
  bool _loading = false;
  String? _error;

  bool get _isFilled => _otp.every((v) => v.isNotEmpty);

  Future<void> _verifyOtp() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('driver_token') ?? '';
    if (token.isEmpty) throw Exception('Not authenticated. Please login again.');

    final response = await http.post(
      Uri.parse('${Auth.apiBaseUrl}/driver/change-password/verify-otp'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'otp': _otp.join()}),
    );
    final data = _safeDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) return;
    throw Exception(_extractApiMessage(data));
  }

  Future<void> _resendOtp() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('driver_token') ?? '';
    if (token.isEmpty) throw Exception('Not authenticated. Please login again.');

    final response = await http.post(
      Uri.parse('${Auth.apiBaseUrl}/driver/change-password/resend-otp'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    final data = _safeDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) return;
    throw Exception(_extractApiMessage(data));
  }

  @override
  Widget build(BuildContext context) {
    final shownEmail = widget.email.trim().isEmpty ? 'your email' : widget.email.trim();
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    width: 43,
                    height: 43,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF2F2F2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back, color: Colors.black, size: 20),
                  ),
                ),
              ),
              const SizedBox(height: 120),
              const Text(
                "Enter OTP Code",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1C1C1C),
                ),
              ),
              const SizedBox(height: 8),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  text: "We sent code to ",
                  style: const TextStyle(fontSize: 15, color: Color(0xFF505050)),
                  children: [
                    TextSpan(
                      text: shownEmail,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF1C1B1F),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 50),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  4,
                  (index) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: _OtpInput(
                      index: index,
                      onChanged: (value) {
                        setState(() => _otp[index] = value);
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: (_isFilled && !_loading)
                      ? () async {
                          setState(() {
                            _loading = true;
                            _error = null;
                          });
                          try {
                            await _verifyOtp();
                            if (!mounted) return;
                            Navigator.pop(context, true);
                          } catch (e) {
                            if (!mounted) return;
                            setState(() {
                              _error = e.toString().replaceFirst('Exception: ', '');
                            });
                          } finally {
                            if (mounted) setState(() => _loading = false);
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        (_isFilled && !_loading) ? const Color(0xFFE3001B) : const Color(0xFFFF9CA7),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    elevation: 0,
                  ),
                  child: Text(_loading ? "Verifying..." : "Continue"),
                ),
              ),
              const SizedBox(height: 35),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Didn’t get OTP? ", style: TextStyle(fontSize: 14.85)),
                  GestureDetector(
                    onTap: _loading
                        ? null
                        : () async {
                            try {
                              await _resendOtp();
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('A new OTP has been sent.')),
                              );
                            } catch (e) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
                              );
                            }
                          },
                    child: const Text(
                      "Resend OTP",
                      style: TextStyle(
                        fontSize: 15,
                        color: Color(0xFFE3001B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OtpInput extends StatelessWidget {
  final int index;
  final ValueChanged<String> onChanged;

  const _OtpInput({required this.index, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 65,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 18,
            spreadRadius: 2,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: TextField(
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        cursorColor: Colors.black,
        cursorHeight: 18,
        cursorWidth: 2,
        cursorRadius: const Radius.circular(3),
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        decoration: const InputDecoration(
          counterText: "",
          border: InputBorder.none,
        ),
        onChanged: (value) {
          onChanged(value);
          if (value.isNotEmpty && index < 3) {
            FocusScope.of(context).nextFocus();
          } else if (value.isEmpty && index > 0) {
            FocusScope.of(context).previousFocus();
          }
        },
      ),
    );
  }
}

Map<String, dynamic> _safeDecode(String body) {
  try {
    return jsonDecode(body) as Map<String, dynamic>;
  } catch (_) {
    return <String, dynamic>{};
  }
}

String _extractApiMessage(Map<String, dynamic> data) {
  final errors = data['errors'];
  if (errors is Map<String, dynamic>) {
    for (final entry in errors.entries) {
      final value = entry.value;
      if (value is List && value.isNotEmpty && value.first is String) {
        return value.first as String;
      }
      if (value is String && value.trim().isNotEmpty) {
        return value;
      }
    }
  }
  final message = data['message'];
  if (message is String && message.trim().isNotEmpty) {
    return message;
  }
  return 'Request failed. Please try again.';
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final String? trailingText;
  final bool showDivider;
  final VoidCallback? onTap;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.trailingText,
    required this.showDivider,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF007CFF);

    Widget rowContent = SizedBox(
      height: 54,
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF797979),
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (trailingText != null) ...[
            const SizedBox(width: 14),
            Text(
              trailingText!,
              style: const TextStyle(
                color: blue,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(
        children: [
          onTap != null
              ? InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(8),
                  child: rowContent,
                )
              : rowContent,
          if (showDivider)
            const Divider(height: 1, thickness: 1, color: Color(0xFFF1F1F1)),
        ],
      ),
    );
  }
}
Future<void> showSuccessDialog(BuildContext context) {
  return showDialog(
    context: context,
    barrierDismissible: true, // allow dismiss by tapping outside
    builder: (context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.83),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 30),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,

            children: [
              const SizedBox(height: 10),
              // Success icon (check circle, green)
              Icon(
                Symbols.check_circle,
                size: 44, // matches previous container size
                color: Color(0xFF22B345),
                fill: 1,
                weight: 400,
                grade: 0,
                opticalSize: 24,
              ),

              const SizedBox(height: 8),

              const Text(
                "Successfully Updated",
                style: TextStyle(fontSize: 19.85, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              const Text(
                "Your phone number has been successfully updated",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.23,
                  color: Color(0xFF5B5B5B),
                  fontWeight: FontWeight.w400,
                ),
              ),

              const SizedBox(height: 10),
            ],
          ),
        ),
      );
    },
  );
}

Future<void> showEmailSuccessDialog(BuildContext context) {
  return showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.83),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 30),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Icon(
                Symbols.check_circle,
                size: 44,
                color: Color(0xFF22B345),
                fill: 1,
                weight: 400,
                grade: 0,
                opticalSize: 24,
              ),
              const SizedBox(height: 8),
              const Text(
                "Successfully Updated",
                style: TextStyle(fontSize: 19.85, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                "Your email has been successfully updated",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.23,
                  color: Color(0xFF5B5B5B),
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      );
    },
  );
}

Future<void> showPasswordSuccessDialog(BuildContext context) {
  return showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.83),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 30),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Icon(
                Symbols.check_circle,
                size: 44,
                color: Color(0xFF22B345),
                fill: 1,
                weight: 400,
                grade: 0,
                opticalSize: 24,
              ),
              const SizedBox(height: 8),
              const Text(
                "Successfully Updated",
                style: TextStyle(fontSize: 19.85, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                "Your password has been successfully updated",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.23,
                  color: Color(0xFF5B5B5B),
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      );
    },
  );
}
