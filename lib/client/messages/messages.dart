import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ice_cream/auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ice_cream/client/favorite/favorite.dart';
import 'package:ice_cream/client/home_page.dart';
import 'package:ice_cream/client/order/all.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

// --- Chat API (Customer ↔ Admin) ---

const String _senderCustomer = 'customer';
const String _senderAdmin = 'admin';

class ChatMessageItem {
  final int id;
  final String senderType;
  final String? body;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime? readAt;

  ChatMessageItem({
    required this.id,
    required this.senderType,
    this.body,
    this.imageUrl,
    required this.createdAt,
    this.readAt,
  });

  bool get isFromCustomer => senderType == _senderCustomer;
  bool get isFromAdmin => senderType == _senderAdmin;

  static ChatMessageItem fromJson(Map<String, dynamic> json) {
    return ChatMessageItem(
      id: (json['id'] as num).toInt(),
      senderType: (json['sender_type'] as String?) ?? _senderCustomer,
      body: json['body'] as String?,
      imageUrl: json['image_url'] as String?,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      readAt: json['read_at'] != null ? DateTime.tryParse(json['read_at'] as String) : null,
    );
  }
}

class ChatSummary {
  final ChatMessageItem? lastMessage;
  final int unreadCount;

  ChatSummary({this.lastMessage, this.unreadCount = 0});

  static ChatSummary fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;
    if (data == null) return ChatSummary();
    final lastMsg = data['last_message'] as Map<String, dynamic>?;
    return ChatSummary(
      lastMessage: lastMsg != null ? ChatMessageItem.fromJson(lastMsg) : null,
      unreadCount: (data['unread_count'] as num?)?.toInt() ?? 0,
    );
  }
}

Future<ChatSummary?> fetchChatSummary() async {
  final token = await Auth.getToken();
  if (token == null) return null;
  final uri = Uri.parse('${Auth.apiBaseUrl}/chat');
  final res = await http.get(
    uri,
    headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
  );
  if (res.statusCode != 200) return null;
  final data = jsonDecode(res.body) as Map<String, dynamic>?;
  if (data == null || data['success'] != true) return null;
  return ChatSummary.fromJson(data);
}

Future<List<ChatMessageItem>?> fetchChatMessages({int page = 1, int perPage = 50}) async {
  final token = await Auth.getToken();
  if (token == null) return null;
  final uri = Uri.parse('${Auth.apiBaseUrl}/chat/messages').replace(
    queryParameters: {'page': '$page', 'per_page': '$perPage'},
  );
  final res = await http.get(
    uri,
    headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
  );
  if (res.statusCode != 200) return null;
  final data = jsonDecode(res.body) as Map<String, dynamic>?;
  if (data == null || data['success'] != true) return null;
  final list = data['data'] as List<dynamic>?;
  if (list == null) return [];
  return list.map((e) => ChatMessageItem.fromJson(e as Map<String, dynamic>)).toList();
}

Future<ChatMessageItem?> sendChatMessage({required String body, String? imagePath}) async {
  final token = await Auth.getToken();
  if (token == null) return null;
  if (imagePath != null) {
    final uri = Uri.parse('${Auth.apiBaseUrl}/chat/messages');
    final request = http.MultipartRequest('POST', uri);
    request.headers['Accept'] = 'application/json';
    request.headers['Authorization'] = 'Bearer $token';
    if (body.trim().isNotEmpty) request.fields['body'] = body.trim();
    request.files.add(await http.MultipartFile.fromPath('image', imagePath));
    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);
    if (res.statusCode != 200) return null;
    final data = jsonDecode(res.body) as Map<String, dynamic>?;
    if (data == null || data['success'] != true) return null;
    final msg = data['data'] as Map<String, dynamic>?;
    return msg != null ? ChatMessageItem.fromJson(msg) : null;
  }
  final uri = Uri.parse('${Auth.apiBaseUrl}/chat/messages');
  final res = await http.post(
    uri,
    headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: jsonEncode({'body': body.trim()}),
  );
  if (res.statusCode != 200) return null;
  final data = jsonDecode(res.body) as Map<String, dynamic>?;
  if (data == null || data['success'] != true) return null;
  final msg = data['data'] as Map<String, dynamic>?;
  return msg != null ? ChatMessageItem.fromJson(msg) : null;
}

Future<bool> markChatRead() async {
  final token = await Auth.getToken();
  if (token == null) return false;
  final uri = Uri.parse('${Auth.apiBaseUrl}/chat/read');
  final res = await http.post(
    uri,
    headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
  );
  return res.statusCode == 200;
}

String formatMessageTime(DateTime dt) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final msgDate = DateTime(dt.year, dt.month, dt.day);
  if (msgDate == today) {
    return DateFormat.jm().format(dt);
  }
  final yesterday = today.subtract(const Duration(days: 1));
  if (msgDate == yesterday) {
    return 'Yesterday ${DateFormat.jm().format(dt)}';
  }
  return DateFormat.yMMMd().add_jm().format(dt);
}

String formatMessageTimeAgo(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24) return '${diff.inHours} hours ago';
  if (diff.inDays < 7) return '${diff.inDays} days ago';
  return DateFormat.yMMMd().format(dt);
}

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  int selectedTab = 0; // 0 = Chats, 1 = Notifications
  ChatSummary? _chatSummary;
  bool _chatLoading = true;
  String? _chatError;

  Timer? _summaryPollTimer;

  @override
  void initState() {
    super.initState();
    _loadChatSummary();
    _startSummaryPolling();
  }

  @override
  void dispose() {
    _summaryPollTimer?.cancel();
    super.dispose();
  }

  void _startSummaryPolling() {
    _summaryPollTimer?.cancel();
    _summaryPollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || selectedTab != 0) return;
      _refreshChatSummarySilent();
    });
  }

  /// Initial load: shows loading indicator.
  Future<void> _loadChatSummary() async {
    setState(() {
      _chatLoading = true;
      _chatError = null;
    });
    try {
      final summary = await fetchChatSummary();
      if (mounted) {
        setState(() {
          _chatSummary = summary;
          _chatLoading = false;
          _chatError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _chatLoading = false;
          _chatError = e.toString();
        });
      }
    }
  }

  /// Real-time background refresh: no loading spinner, only updates data when changed.
  Future<void> _refreshChatSummarySilent() async {
    try {
      final summary = await fetchChatSummary();
      if (mounted) {
        setState(() {
          _chatSummary = summary;
          _chatError = null;
        });
      }
    } catch (_) {
      // Keep previous state on silent refresh failure
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      bottomNavigationBar: _bottomNavBar(context),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 15),
            // ---------------- TOP BAR ----------------
   Padding(
  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      const Text(
        "Messages",
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
      ),
      IconButton(
        icon: const Icon(
          Symbols.delete, // ✅ Material Symbols icon
          size: 25,
          color: Colors.black,

          // ✅ matches your CSS:
          fill: 0,
          weight: 200,
          grade: 200,
          opticalSize: 24,
        ),
        onPressed: () => _showDeleteAllModal(context),
      ),
    ],
  ),
),

            const SizedBox(height: 10),

            // ---------------- TABS ----------------
            Row(
              children: [
                const SizedBox(width: 20),

                // Chats tab
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => selectedTab = 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: selectedTab == 0
                            ? const Color(0xFFE3001B)
                            : const Color(0xFFFCE8E9), // inactive bg
                        borderRadius: BorderRadius.circular(30),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        "Chats",
                        style: TextStyle(
                          fontSize: 14,
                          color: selectedTab == 0
                              ? Colors.white
                              : const Color(0xFF1C1B1F), // inactive text
                          fontWeight: selectedTab == 0
                              ? FontWeight.w400
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                // Notifications tab
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => selectedTab = 1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 20,
                      ), // add horizontal padding
                      decoration: BoxDecoration(
                        color: selectedTab == 1
                            ? const Color(0xFFE3001B)
                            : const Color(0xFFFCE8E9),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Slightly left-shifted Text
                          Align(
                            alignment: Alignment.center,
                            child: Padding(
                              padding: const EdgeInsets.only(
                                right: 10,
                              ), // moves text a bit to the left
                              child: Text(
                                "Notifications",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: selectedTab == 1
                                      ? Colors.white
                                      : const Color(0xFF1C1B1F),
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          ),

                          // Positioned Badge (unread count from API)
                          if ((_chatSummary?.unreadCount ?? 0) > 0)
                            Positioned(
                              right: -12,
                              child: Container(
                                width: 19,
                                height: 19,
                                decoration: BoxDecoration(
                                  color: selectedTab == 1
                                      ? Colors.white
                                      : const Color(0xFFE3001B),
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  (_chatSummary!.unreadCount > 99)
                                      ? '99+'
                                      : '${_chatSummary!.unreadCount}',
                                  style: TextStyle(
                                    color: selectedTab == 1
                                        ? const Color(0xFFE3001B)
                                        : Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 20),
              ],
            ),

            const SizedBox(height: 20),

            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  if (selectedTab == 0) {
                    await _loadChatSummary();
                  }
                },
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    if (selectedTab == 0) ...[
                      // ----------------- CHATS (real API: single Admin chat) -----------------
                      if (_chatLoading)
                        const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (_chatError != null)
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              Text(
                                _chatError!,
                                style: const TextStyle(color: Colors.red),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              TextButton(
                                onPressed: _loadChatSummary,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      else
                        GestureDetector(
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ChatPage(),
                              ),
                            );
                            if (mounted) _refreshChatSummarySilent();
                          },
                          child: messageCard(
                            icon: Icons.support_agent,
                            name: 'Chat with H&R Ice Cream',
                            message: _chatSummary?.lastMessage != null
                                ? (_chatSummary!.lastMessage!.body ?? 'Image')
                                : 'No messages yet. Tap to start.',
                            time: _chatSummary?.lastMessage != null
                                ? formatMessageTimeAgo(_chatSummary!.lastMessage!.createdAt)
                                : '',
                          ),
                        ),
                      const SizedBox(height: 10),
                    ] else ...[
                    notificationCard(
                      message:
                          "Your order Strawberry has been successfully delivered.",
                      time: "1 minute ago",
                      isFirst: true,
                    ),
                    const SizedBox(height: 13),
                    notificationCard(
                      message: "Your order Mango Graham has been cancelled.",
                      time: "4 hours ago",
                    ),
                    const SizedBox(height: 13),
                    notificationCard(
                      message: "Your personal has been updated.",
                      time: "4:15 pm",
                    ),
                    const SizedBox(height: 13),
                    notificationCard(
                      message: "Your order Ube Cheese has been cancelled.",
                      time: "6 hours ago",
                    ),
                    const SizedBox(height: 13),
                    notificationCard(
                      message: "Your order Mango Graham has been cancelled.",
                      time: "4 hours ago",
                    ),
                    const SizedBox(height: 13),
                    notificationCard(
                      message: "Your personal has been updated.",
                      time: "4:15 pm",
                    ),
                    const SizedBox(height: 13),
                    notificationCard(
                      message: "Your order Ube Cheese has been cancelled.",
                      time: "6 hours ago",
                    ),
                    const SizedBox(height: 13),
                  ],
                ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteAllModal(BuildContext context) {
    // Determine the correct title based on active tab
    String title = selectedTab == 1
        ? "Delete all notifications?"
        : "Delete all messages?";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 25),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(35),
              topRight: Radius.circular(35),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1C1B1F),
                ),
              ),

              const SizedBox(height: 5),

              // Subtitle
              const Text(
                "You can’t undo this later.",
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF747474),
                  fontWeight: FontWeight.w400,
                ),
              ),

              const SizedBox(height: 30),

              // DELETE ALL button
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  // Add your delete logic (messages or notifications)
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3001B),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    "Delete All",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // KEEP THEM button
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F4F4),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    "Keep Them",
                    style: TextStyle(
                      color: Color(0xFF414141),
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  // ---------------- BOTTOM NAV BAR ----------------
  Widget _bottomNavBar(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(left: 18, right: 18, bottom: 12),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      elevation: 0,
      child: SizedBox(
        height: 65,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _BottomIcon(
              icon: Symbols.home,
              label: "Home",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HomePage()),
                );
              },
            ),
            _BottomIcon(
              icon: Symbols.local_mall,
              label: "Order",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const OrderHistoryPage()),
                );
              },
            ),
            _BottomIcon(
              icon: Symbols.favorite,
              label: "Favorite",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FavoritePage()),
                );
              },
            ),
            _BottomIcon(
              icon: Symbols.chat,
              label: "Messages",
              active: true,
              onTap: () {},
              fillColor: const Color(0xFFE3001B),
            ),
          ],
        ),
      ),
    );
  }

  Widget messageCard({
    required IconData icon,
    required String name,
    required String message,
    required String time,
  })

{
  // Determine icon, size, fill, and padding based on passed icon
  IconData displayedIcon;
  double iconSize;
  double containerPadding;

  // Material Symbols variations
  double iconFill;
  double iconWeight;
  double iconGrade;
  double iconOpticalSize;

  if (icon == Icons.person) {
    // ✅ Person in Material Symbols style (FILL 1, wght 700, GRAD 200, opsz 24)
    displayedIcon = Symbols.person;
    iconSize = 22;
    containerPadding = 14;

    iconFill = 1;
    iconWeight = 600;
    iconGrade = 200;
    iconOpticalSize = 24;
  } else {
    displayedIcon = Symbols.nest_mini;
    iconSize = 24;
    containerPadding = 12;

    // keep your other icon style (adjust if you want)
    iconFill = 1;
    iconWeight = 600;
    iconGrade = 0;
    iconOpticalSize = 24;
  }

  return Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: const Color(0xFFFFFFFF),
      borderRadius: BorderRadius.circular(11),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Transform.translate(
          offset: const Offset(-4, 0),
          child: Container(
            padding: EdgeInsets.all(containerPadding),
            decoration: const BoxDecoration(
              color: Color(0xFFFFE7EA),
              shape: BoxShape.circle,
            ),
            child: Icon(
              displayedIcon,
              size: iconSize,
              color: const Color(0xFFE3001B),

              // ✅ Material Symbols variations (matches your CSS)
              fill: iconFill,
              weight: iconWeight,
              grade: iconGrade,
              opticalSize: iconOpticalSize,
            ),
          ),
        ),
        const SizedBox(width: 10),

        Expanded(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Transform.translate(
                offset: const Offset(0, -4),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 7),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        message,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF1C1B1F),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: -3,
                right: 0,
                child: Text(
                  time,
                  style: const TextStyle(fontSize: 12, color: Colors.black45),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

  Widget notificationCard({
    required String message,
    required String time,
    bool isFirst = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(11),
        boxShadow: isFirst
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.10),
                  blurRadius: 12,
                  spreadRadius: 1,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: Row(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Transform.translate(
      offset: const Offset(-4, 0),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: const BoxDecoration(
          color: Color(0xFFFFE7EA),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Symbols.notifications_active,
          size: 22,
          color: Color(0xFFE3001B),

          // ✅ matches your CSS
          fill: 1,
          weight: 600,
          grade: 0,
          opticalSize: 24,
        ),
      ),
    ),

    const SizedBox(width: 10),

    Expanded(
      child: SizedBox(
        height: 52,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF1C1B1F),
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                time,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black45,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  ],
),
    );
  }
}

class _BottomIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  final Color? fillColor; // New parameter for custom fill color

  const _BottomIcon({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
    this.fillColor, // Allow fillColor to be passed
  });

  @override
  Widget build(BuildContext context) {
    final Color iconColor = active ? Color(0xFFE3001B) : const Color(0xFF969696);
    final double fillValue = (active && fillColor != null) ? 1 : 0;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(0),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 21,
              color: fillColor != null && active ? fillColor : iconColor,
              fill: fillValue,
              weight: 100,
              grade: 200,
              opticalSize: 24,
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: iconColor,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with WidgetsBindingObserver {
  static const double avatarRadius = 22;
  static const Duration _pollInterval = Duration(seconds: 2);

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<ChatMessageItem> _messages = [];
  bool _loading = true;
  String? _error;
  bool _sending = false;
  Timer? _pollTimer;
  bool _isAppInForeground = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadMessages();
    markChatRead();
    _startPolling();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollTimer?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    final inForeground = state == AppLifecycleState.resumed;
    if (_isAppInForeground != inForeground) {
      _isAppInForeground = inForeground;
      if (inForeground) {
        _refreshMessagesInBackground();
        _startPolling();
      } else {
        _pollTimer?.cancel();
      }
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_pollInterval, (_) {
      if (_isAppInForeground) _refreshMessagesInBackground();
    });
  }

  /// Refetch messages in background (no loading spinner). Update list if changed; scroll to bottom if new messages and user was near bottom.
  Future<void> _refreshMessagesInBackground() async {
    if (!mounted || _loading || _sending) return;
    try {
      final list = await fetchChatMessages(perPage: 100);
      if (!mounted || list == null) return;
      final prevCount = _messages.length;
      final prevLastId = _messages.isNotEmpty ? _messages.last.id : 0;
      final newCount = list.length;
      final newLastId = list.isNotEmpty ? list.last.id : 0;
      if (newCount != prevCount || newLastId != prevLastId) {
        final wasNearBottom = _scrollController.hasClients &&
            (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 80);
        setState(() => _messages = list);
        if (wasNearBottom) _scrollToBottom();
      }
    } catch (_) {
      // ignore errors in background poll
    }
  }

  Future<void> _loadMessages() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await fetchChatMessages(perPage: 100);
      if (mounted) {
        setState(() {
          _messages = list ?? [];
          _loading = false;
          _error = null;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    _controller.clear();
    setState(() => _sending = true);
    try {
      final sent = await sendChatMessage(body: text);
      if (mounted && sent != null) {
        setState(() {
          _messages = [..._messages, sent];
          _sending = false;
        });
        _scrollToBottom();
      } else {
        if (mounted) setState(() => _sending = false);
      }
    } catch (_) {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _pickAndSendImage() async {
    if (_sending) return;
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null || !mounted) return;
    final path = file.path;
    if (path.isEmpty) return;
    setState(() => _sending = true);
    try {
      final sent = await sendChatMessage(body: '', imagePath: path);
      if (mounted && sent != null) {
        setState(() {
          _messages = [..._messages, sent];
          _sending = false;
        });
        _scrollToBottom();
      } else {
        if (mounted) setState(() => _sending = false);
      }
    } catch (_) {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 15),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 3),
                    child: IconButton(
                      icon: const Icon(
                        Symbols.arrow_back_ios,
                        size: 22,
                        weight: 400,
                        color: Colors.black,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 0),
                  const CircleAvatar(
                    radius: avatarRadius,
                    backgroundColor: Color(0xFFFFE5E5),
                    child: Icon(
                      Symbols.support_agent,
                      color: Color(0xFFE3001B),
                      size: 21,
                      fill: 1,
                      weight: 700,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Chat with H&R Ice Cream',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Support',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  children: [
                    Expanded(
                      child: _loading
                          ? const Center(child: CircularProgressIndicator())
                          : _error != null
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        _error!,
                                        style: const TextStyle(color: Colors.red),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 12),
                                      TextButton(
                                        onPressed: _loadMessages,
                                        child: const Text('Retry'),
                                      ),
                                    ],
                                  ),
                                )
                              : RefreshIndicator(
                                  onRefresh: () async {
                                    await _loadMessages();
                                  },
                                  child: ListView.builder(
                                    physics: const AlwaysScrollableScrollPhysics(),
                                    controller: _scrollController,
                                    itemCount: _messages.length,
                                    itemBuilder: (context, index) {
                                      final m = _messages[index];
                                      return _buildMessageBubble(m);
                                    },
                                  ),
                                ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 0, left: 0, right: 0, bottom: 3),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: _sending ? null : _pickAndSendImage,
                            icon: const Icon(
                              Symbols.attach_file,
                              size: 26,
                              color: Color(0xFFE3001B),
                              fill: 0,
                              weight: 400,
                              opticalSize: 24,
                            ),
                          ),
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              style: const TextStyle(fontSize: 15),
                              decoration: InputDecoration(
                                hintText: 'Message',
                                hintStyle: const TextStyle(
                                  color: Color(0xFF464646),
                                  fontSize: 15,
                                ),
                                filled: true,
                                fillColor: const Color(0xFFF1F1F1),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 14,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              onSubmitted: (_) => _sendMessage(),
                            ),
                          ),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: _sending ? null : _sendMessage,
                            child: CircleAvatar(
                              radius: 24,
                              backgroundColor: _sending
                                  ? Colors.grey
                                  : const Color(0xFFE3001B),
                              child: _sending
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(
                                      Symbols.send,
                                      color: Colors.white,
                                      size: 22,
                                      weight: 600,
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessageItem m) {
    final isCustomer = m.isFromCustomer;
    final timeStr = formatMessageTime(m.createdAt);

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Align(
        alignment: isCustomer ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: isCustomer ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (!isCustomer) ...[
                  const CircleAvatar(
                    radius: avatarRadius,
                    backgroundColor: Color(0xFFFFE5E5),
                    child: Icon(
                      Symbols.support_agent,
                      color: Color(0xFFE3001B),
                      size: 21,
                      fill: 1,
                      weight: 700,
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                    decoration: BoxDecoration(
                      color: isCustomer
                          ? const Color(0xFFE3001B)
                          : const Color(0xFFEAEAEA),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (m.imageUrl != null && m.imageUrl!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Image.network(
                              m.imageUrl!,
                              width: 200,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
                            ),
                          ),
                        if (m.body != null && m.body!.isNotEmpty)
                          Text(
                            m.body!,
                            style: TextStyle(
                              fontWeight: FontWeight.w400,
                              color: isCustomer ? Colors.white : Colors.black,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                if (isCustomer) ...[
                  const SizedBox(width: 10),
                  const CircleAvatar(
                    radius: avatarRadius,
                    backgroundColor: Color(0xFFFFE5E5),
                    child: Icon(
                      Symbols.person,
                      color: Color(0xFFE3001B),
                      size: 21,
                      fill: 1,
                      weight: 700,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 6),
            Padding(
              padding: EdgeInsets.only(
                left: isCustomer ? 0 : (avatarRadius * 2) + 10,
                right: isCustomer ? (avatarRadius * 2) + 10 : 0,
              ),
              child: Text(
                timeStr,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF1C1B1F),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
