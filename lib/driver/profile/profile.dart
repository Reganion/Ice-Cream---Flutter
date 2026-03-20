import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ice_cream/auth.dart';
import 'package:ice_cream/driver/login.dart';
import 'package:ice_cream/services/fcm_push_service.dart';
import 'package:ice_cream/driver/profile/edit_email_address_page.dart';
import 'package:ice_cream/driver/profile/edit_password_page.dart';
import 'package:ice_cream/driver/profile/edit_phone_number_page.dart';
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
    await FcmPushService.clearDriverToken();
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
                          onTap: () async {
                            final updatedPhone = await Navigator.push<String>(
                              context,
                              MaterialPageRoute<String>(
                                builder: (context) => EditPhoneNumberPage(
                                  initialPhone: _phone,
                                ),
                              ),
                            );
                            if (updatedPhone == null ||
                                updatedPhone.trim().isEmpty) {
                              return;
                            }
                            if (!mounted) return;
                            setState(() {
                              _driver['phone'] = updatedPhone.trim();
                            });
                            await _saveDriverProfileCache();
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
