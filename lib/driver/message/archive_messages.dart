import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ice_cream/auth.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ArchiveMessagesPage extends StatefulWidget {
  const ArchiveMessagesPage({super.key});

  @override
  State<ArchiveMessagesPage> createState() => _ArchiveMessagesPageState();
}

class _ArchiveMessagesPageState extends State<ArchiveMessagesPage> {
  bool _loading = true;
  bool _refreshing = false;
  String _error = '';
  List<Map<String, dynamic>> _threads = [];

  static const Duration _apiTimeout = Duration(seconds: 12);

  Future<String?> _token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('driver_token');
  }

  String _timeAgo(String? iso) {
    if (iso == null || iso.trim().isEmpty) return '';
    final dt = DateTime.tryParse(iso)?.toLocal();
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays > 0) return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
    if (diff.inHours > 0) return '${diff.inHours} hour${diff.inHours == 1 ? '' : 's'} ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes} min ago';
    return 'Just now';
  }

  Future<void> _fetchArchivedThreads() async {
    final isRefresh = _threads.isNotEmpty;
    setState(() {
      if (isRefresh) {
        _refreshing = true;
      } else {
        _loading = true;
        _error = '';
      }
    });
    try {
      final token = await _token();
      if (token == null || token.isEmpty) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _refreshing = false;
          _error = 'Missing driver session. Please login again.';
          _threads = [];
        });
        return;
      }
      final uri = Uri.parse('${Auth.apiBaseUrl}/driver/messages/archived-threads');
      final res = await http
          .get(
            uri,
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(_apiTimeout);
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (!mounted) return;
      if (res.statusCode != 200 || data['success'] != true) {
        setState(() {
          _threads = [];
          _loading = false;
          _refreshing = false;
          _error = (data['message'] ?? 'Could not load archived messages.').toString();
        });
        return;
      }
      final raw = data['data'];
      final list = raw is List
          ? raw
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList()
          : <Map<String, dynamic>>[];
      setState(() {
        _threads = list;
        _loading = false;
        _refreshing = false;
        _error = '';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _refreshing = false;
        _threads = [];
        _error = 'Could not load archived messages. Check connection.';
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchArchivedThreads();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              color: const Color(0xFFFAFAFA),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Symbols.arrow_back_ios,
                      size: 22,
                      weight: 400,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Text(
                    'Archived Messages',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1C1B1F),
                    ),
                  ),
                  if (_refreshing) ...[
                    const SizedBox(width: 8),
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE3001B)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : _error.isNotEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _error,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Color(0xFFE3001B)),
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton(
                                  onPressed: _fetchArchivedThreads,
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : _threads.isEmpty
                          ? const Center(
                              child: Text(
                                'No archived message threads.',
                                style: TextStyle(color: Color(0xFF666666)),
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _fetchArchivedThreads,
                              child: ListView.separated(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                itemCount: _threads.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 10),
                                itemBuilder: (_, index) {
                                  final thread = _threads[index];
                                  final shipmentId = thread['shipment_id'] is int
                                      ? thread['shipment_id'] as int
                                      : int.tryParse((thread['shipment_id'] ?? '').toString()) ?? 0;
                                  final name = (thread['customer_name'] ?? thread['customer_phone'] ?? 'Customer').toString().trim();
                                  final preview = (thread['last_message'] ?? '').toString();
                                  final time = _timeAgo((thread['last_message_at'] ?? '').toString());
                                  return GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ArchiveChatPage(
                                            shipmentId: shipmentId,
                                            customerName: name.isEmpty ? 'Customer' : name,
                                            customerPhone: (thread['customer_phone'] ?? '').toString(),
                                          ),
                                        ),
                                      ).then((_) => _fetchArchivedThreads());
                                    },
                                    child: _ArchiveMessageCard(
                                      name: name.isEmpty ? 'Shipment #$shipmentId' : name,
                                      message: preview.isEmpty ? 'No message' : preview,
                                      time: time.isEmpty ? 'Archived' : time,
                                    ),
                                  );
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArchiveMessageCard extends StatelessWidget {
  const _ArchiveMessageCard({
    required this.name,
    required this.message,
    required this.time,
  });

  final String name;
  final String message;
  final String time;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: Color(0xFFFFE7EA),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Symbols.inventory_2,
              size: 22,
              color: Color(0xFFE3001B),
              fill: 1,
              weight: 600,
              grade: 200,
              opticalSize: 24,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Padding(
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
                Positioned(
                  bottom: -3,
                  right: 0,
                  child: Text(
                    time,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF616161),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ArchiveConversationMessage {
  const _ArchiveConversationMessage({
    required this.text,
    required this.time,
    required this.isDriver,
  });

  final String text;
  final String time;
  final bool isDriver;
}

class _ArchiveMsg {
  final int id;
  final String message;
  final bool isMine;
  final DateTime? createdAt;

  const _ArchiveMsg({
    required this.id,
    required this.message,
    required this.isMine,
    this.createdAt,
  });

  static _ArchiveMsg fromMap(Map<String, dynamic> json) {
    final createdAtRaw = json['created_at']?.toString();
    return _ArchiveMsg(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      message: (json['message'] ?? '').toString(),
      isMine: json['is_mine'] == true,
      createdAt: createdAtRaw == null ? null : DateTime.tryParse(createdAtRaw)?.toLocal(),
    );
  }
}

class ArchiveChatPage extends StatefulWidget {
  const ArchiveChatPage({
    super.key,
    required this.shipmentId,
    required this.customerName,
    this.customerPhone,
  });

  final int shipmentId;
  final String customerName;
  final String? customerPhone;

  static const double avatarRadius = 22;

  @override
  State<ArchiveChatPage> createState() => _ArchiveChatPageState();
}

class _ArchiveChatPageState extends State<ArchiveChatPage> {
  final TextEditingController _messageCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  bool _loading = true;
  bool _sending = false;
  String _error = '';
  List<_ArchiveMsg> _messages = [];

  static const Duration _timeout = Duration(seconds: 15);

  Future<String?> _token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('driver_token');
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    final hour24 = dt.hour;
    final minute = dt.minute.toString().padLeft(2, '0');
    final suffix = hour24 >= 12 ? 'pm' : 'am';
    final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
    return '$hour12:$minute $suffix';
  }

  Future<void> _loadMessages() async {
    setState(() => _error = '');
    try {
      final token = await _token();
      if (token == null || token.isEmpty) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _error = 'Missing driver session. Please login again.';
          _messages = [];
        });
        return;
      }
      final uri = Uri.parse('${Auth.apiBaseUrl}/driver/shipments/${widget.shipmentId}/messages')
          .replace(queryParameters: const {'status': 'archive'});
      final res = await http
          .get(
            uri,
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(_timeout);
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (!mounted) return;
      if (res.statusCode != 200 || data['success'] != true || data['data'] is! List) {
        setState(() {
          _loading = false;
          _messages = [];
          _error = (data['message'] ?? 'Could not load messages.').toString();
        });
        return;
      }
      final list = (data['data'] as List)
          .whereType<Map>()
          .map((e) => _ArchiveMsg.fromMap(Map<String, dynamic>.from(e)))
          .toList();
      list.sort((a, b) {
        final aAt = a.createdAt;
        final bAt = b.createdAt;
        if (aAt == null && bAt == null) return a.id.compareTo(b.id);
        if (aAt == null) return -1;
        if (bAt == null) return 1;
        final c = aAt.compareTo(bAt);
        return c != 0 ? c : a.id.compareTo(b.id);
      });
      setState(() {
        _messages = list;
        _loading = false;
        _error = '';
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollCtrl.hasClients) {
          _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _messages = [];
        _error = 'Could not load messages. Check connection.';
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageCtrl.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final token = await _token();
      if (token == null || token.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Missing driver session. Please login again.')),
          );
        }
        return;
      }
      final res = await http.post(
        Uri.parse('${Auth.apiBaseUrl}/driver/shipments/${widget.shipmentId}/messages'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'message': text, 'status': 'archive'}),
      );
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (!mounted) return;
      if ((res.statusCode == 201 || res.statusCode == 200) && data['success'] == true) {
        _messageCtrl.clear();
        await _loadMessages();
      } else {
        final msg = (data['message'] ?? 'Could not send message.').toString();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not send message. Check connection.')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _messageCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
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
                  IconButton(
                    icon: const Icon(
                      Symbols.arrow_back_ios,
                      size: 22,
                      weight: 400,
                      color: Colors.black,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const CircleAvatar(
                    radius: ArchiveChatPage.avatarRadius,
                    backgroundColor: Color(0xFFFFE5E5),
                    child: Icon(
                      Symbols.person,
                      color: Color(0xFFE3001B),
                      size: 21,
                      fill: 1,
                      weight: 700,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.customerName,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          (widget.customerPhone ?? '').isEmpty
                              ? 'Shipment #${widget.shipmentId}'
                              : widget.customerPhone!,
                          style: const TextStyle(color: Colors.grey, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _error.isNotEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _error,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Color(0xFFE3001B)),
                            ),
                            const SizedBox(height: 10),
                            ElevatedButton(
                              onPressed: _loadMessages,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _loading && _messages.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                              SizedBox(height: 12),
                              Text(
                                'Loading messages...',
                                style: TextStyle(color: Color(0xFF666666), fontSize: 14),
                              ),
                            ],
                          ),
                        )
                      : _messages.isEmpty
                          ? const Center(
                              child: Text(
                                'No messages in this thread.',
                                style: TextStyle(color: Color(0xFF666666), fontSize: 14),
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _loadMessages,
                              child: ListView.builder(
                                controller: _scrollCtrl,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                itemCount: _messages.length,
                                itemBuilder: (_, index) {
                                  final m = _messages[index];
                                  final bubble = _ArchiveConversationMessage(
                                    text: m.message,
                                    time: _formatTime(m.createdAt),
                                    isDriver: m.isMine,
                                  );
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 20),
                                    child: _ArchiveChatBubble(message: bubble),
                                  );
                                },
                              ),
                            ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, bottom: 14),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageCtrl,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
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
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _sending ? null : _sendMessage,
                    child: CircleAvatar(
                      radius: 24,
                      backgroundColor: _sending
                          ? const Color(0xFFB56973)
                          : const Color(0xFFE3001B),
                      child: _sending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
    );
  }
}

class _ArchiveChatBubble extends StatelessWidget {
  const _ArchiveChatBubble({required this.message});

  final _ArchiveConversationMessage message;

  static const double avatarRadius = 22;

  @override
  Widget build(BuildContext context) {
    if (message.isDriver) {
      return Align(
        alignment: Alignment.centerRight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3001B),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      message.text,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ),
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
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(right: (avatarRadius * 2) + 10),
              child: Text(
                message.time,
                style: const TextStyle(fontSize: 11, color: Color(0xFF1C1B1F)),
              ),
            ),
          ],
        ),
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
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
              const SizedBox(width: 10),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAEAEA),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    message.text,
                    style: const TextStyle(fontWeight: FontWeight.w400),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: (avatarRadius * 2) + 10),
            child: Text(
              message.time,
              style: const TextStyle(fontSize: 11, color: Color(0xFF1C1B1F)),
            ),
          ),
        ],
      ),
    );
  }
}
