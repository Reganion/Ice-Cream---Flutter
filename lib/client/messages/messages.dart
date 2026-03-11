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

// --- Order Message API (Customer <-> Driver) ---

class DriverOrderThread {
  final int orderId;
  final List<int> relatedOrderIds;
  final String driverName;
  final String driverContact;
  final String transactionId;
  final String orderLabel;
  final String? preview;
  final DateTime? lastAt;

  const DriverOrderThread({
    required this.orderId,
    this.relatedOrderIds = const [],
    required this.driverName,
    this.driverContact = '',
    required this.transactionId,
    required this.orderLabel,
    this.preview,
    this.lastAt,
  });

  DriverOrderThread copyWith({
    int? orderId,
    List<int>? relatedOrderIds,
    String? driverName,
    String? driverContact,
    String? transactionId,
    String? orderLabel,
    String? preview,
    DateTime? lastAt,
  }) {
    return DriverOrderThread(
      orderId: orderId ?? this.orderId,
      relatedOrderIds: relatedOrderIds ?? this.relatedOrderIds,
      driverName: driverName ?? this.driverName,
      driverContact: driverContact ?? this.driverContact,
      transactionId: transactionId ?? this.transactionId,
      orderLabel: orderLabel ?? this.orderLabel,
      preview: preview ?? this.preview,
      lastAt: lastAt ?? this.lastAt,
    );
  }
}

class OrderMessageItem {
  final int id;
  final int orderId;
  final String senderType;
  final String message;
  final bool isMine;
  final DateTime? createdAt;

  const OrderMessageItem({
    required this.id,
    required this.orderId,
    required this.senderType,
    required this.message,
    required this.isMine,
    required this.createdAt,
  });

  factory OrderMessageItem.fromJson(Map<String, dynamic> json) {
    final idRaw = json['id'];
    final orderIdRaw = json['order_id'];
    final createdAtRaw = json['created_at']?.toString();
    return OrderMessageItem(
      id: idRaw is int ? idRaw : int.tryParse(idRaw?.toString() ?? '') ?? 0,
      orderId: orderIdRaw is int ? orderIdRaw : int.tryParse(orderIdRaw?.toString() ?? '') ?? 0,
      senderType: (json['sender_type'] ?? '').toString(),
      message: (json['message'] ?? '').toString(),
      isMine: json['is_mine'] == true,
      createdAt: createdAtRaw == null ? null : DateTime.tryParse(createdAtRaw)?.toLocal(),
    );
  }
}

Future<List<OrderMessageItem>?> fetchOrderMessages({
  required int orderId,
  int perPage = 100,
}) async {
  final token = await Auth.getToken();
  if (token == null || token.isEmpty) return null;
  final uri = Uri.parse('${Auth.apiBaseUrl}/orders/$orderId/messages')
      .replace(queryParameters: {'per_page': '$perPage'});
  final res = await http.get(
    uri,
    headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
  );
  final data = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200 || data == null || data['success'] != true) return null;
  final list = data['data'] as List<dynamic>?;
  if (list == null) return [];
  return list
      .whereType<Map>()
      .map((e) => OrderMessageItem.fromJson(Map<String, dynamic>.from(e)))
      .toList();
}

Future<OrderMessageItem?> sendOrderMessage({
  required int orderId,
  required String message,
}) async {
  final token = await Auth.getToken();
  if (token == null || token.isEmpty) return null;
  final res = await http.post(
    Uri.parse('${Auth.apiBaseUrl}/orders/$orderId/messages'),
    headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: jsonEncode({'message': message.trim()}),
  );
  final data = jsonDecode(res.body) as Map<String, dynamic>?;
  if (data == null || data['success'] != true) return null;
  final item = data['data'] as Map<String, dynamic>?;
  return item == null ? null : OrderMessageItem.fromJson(item);
}

Future<bool> markOrderMessagesRead({required int orderId}) async {
  final token = await Auth.getToken();
  if (token == null || token.isEmpty) return false;
  final res = await http.post(
    Uri.parse('${Auth.apiBaseUrl}/orders/$orderId/messages/read'),
    headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
  );
  return res.statusCode == 200;
}

DateTime? _parseDateTimeMaybe(dynamic value) {
  final s = value?.toString();
  if (s == null || s.trim().isEmpty) return null;
  return DateTime.tryParse(s)?.toLocal();
}

String _pickFirstNonEmpty(List<dynamic> values) {
  for (final v in values) {
    final s = (v ?? '').toString().trim();
    if (s.isNotEmpty) return s;
  }
  return '';
}

String _extractDriverNameFromOrder(Map<String, dynamic> order) {
  String fullFromParts(Map<String, dynamic> src) {
    final first = _pickFirstNonEmpty([
      src['firstname'],
      src['first_name'],
      src['given_name'],
      src['driver_first_name'],
      src['assigned_driver_first_name'],
      src['rider_first_name'],
    ]);
    final last = _pickFirstNonEmpty([
      src['lastname'],
      src['last_name'],
      src['family_name'],
      src['driver_last_name'],
      src['assigned_driver_last_name'],
      src['rider_last_name'],
    ]);
    final full = '$first $last'.trim();
    return full;
  }

  final direct = _pickFirstNonEmpty([
    order['driver_name'],
    order['assigned_driver_name'],
    order['rider_name'],
    order['driver_full_name'],
    order['driver_display_name'],
  ]);
  if (direct.isNotEmpty) return direct;

  final nestedDriverRaw = order['driver'] ?? order['assigned_driver'] ?? order['rider'];
  if (nestedDriverRaw is Map) {
    final nested = Map<String, dynamic>.from(nestedDriverRaw);
    final nestedDirect = _pickFirstNonEmpty([
      nested['name'],
      nested['full_name'],
      nested['driver_name'],
      nested['display_name'],
    ]);
    if (nestedDirect.isNotEmpty) return nestedDirect;
    final fromParts = fullFromParts(nested);
    if (fromParts.isNotEmpty) return fromParts;
  }

  final fromTopParts = fullFromParts(order);
  if (fromTopParts.isNotEmpty) return fromTopParts;

  return '';
}

String _extractDriverContactFromOrder(Map<String, dynamic> order) {
  final direct = _pickFirstNonEmpty([
    order['driver_phone'],
    order['driver_contact'],
    order['assigned_driver_phone'],
    order['assigned_driver_contact'],
    order['rider_phone'],
    order['rider_contact'],
  ]);
  if (direct.isNotEmpty) return direct;

  final nestedDriverRaw = order['driver'] ?? order['assigned_driver'] ?? order['rider'];
  if (nestedDriverRaw is Map) {
    final nested = Map<String, dynamic>.from(nestedDriverRaw);
    final nestedContact = _pickFirstNonEmpty([
      nested['contact_no'],
      nested['contact_number'],
      nested['phone'],
      nested['mobile'],
      nested['mobile_number'],
    ]);
    if (nestedContact.isNotEmpty) return nestedContact;
  }

  return '';
}

String _extractDriverGroupKeyFromOrder(Map<String, dynamic> order, String fallbackName) {
  final directId = _pickFirstNonEmpty([
    order['driver_id'],
    order['assigned_driver_id'],
    order['rider_id'],
  ]);
  if (directId.isNotEmpty) return 'id:$directId';

  final nestedDriverRaw = order['driver'] ?? order['assigned_driver'] ?? order['rider'];
  if (nestedDriverRaw is Map) {
    final nested = Map<String, dynamic>.from(nestedDriverRaw);
    final nestedId = _pickFirstNonEmpty([
      nested['id'],
      nested['driver_id'],
      nested['user_id'],
      nested['account_id'],
    ]);
    if (nestedId.isNotEmpty) return 'id:$nestedId';
    final nestedPhone = _pickFirstNonEmpty([
      nested['phone'],
      nested['mobile'],
      nested['contact_number'],
    ]);
    if (nestedPhone.isNotEmpty) return 'phone:$nestedPhone';
  }

  final fallback = fallbackName.trim().toLowerCase();
  if (fallback.isNotEmpty) return 'name:$fallback';
  return 'order:${order['id'] ?? ''}';
}

Future<List<DriverOrderThread>> fetchDriverOrderThreads() async {
  final token = await Auth.getToken();
  if (token == null || token.isEmpty) return [];
  final uri = Uri.parse('${Auth.apiBaseUrl}/orders').replace(
    queryParameters: {'status': 'all'},
  );
  final res = await http.get(
    uri,
    headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
  );
  final data = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200 || data == null) return [];
  final list = data['data'] as List<dynamic>? ?? [];
  final grouped = <String, DriverOrderThread>{};

  for (final raw in list.whereType<Map>()) {
    final order = Map<String, dynamic>.from(raw);
    final rawDriverId = (order['driver_id'] ?? '').toString().trim();
    if (rawDriverId.isEmpty || rawDriverId == '0' || rawDriverId == 'null') {
      // Skip orders without an assigned driver; they usually show generic "Driver".
      continue;
    }
    final orderIdRaw = order['id'];
    final orderId = orderIdRaw is int ? orderIdRaw : int.tryParse(orderIdRaw?.toString() ?? '');
    if (orderId == null) continue;

    var driverName = _extractDriverNameFromOrder(order);
    if (driverName.isEmpty) driverName = 'Driver';
    final driverContact = _extractDriverContactFromOrder(order);
    final transactionId = (order['transaction_id'] ?? 'Order #$orderId').toString();
    final orderLabel = (order['product_name'] ?? order['product_type'] ?? 'Order').toString();
    final lastAt = _parseDateTimeMaybe(order['updated_at']) ??
        _parseDateTimeMaybe(order['created_at']) ??
        _parseDateTimeMaybe(order['delivery_date']);
    final preview = _pickFirstNonEmpty([
      order['latest_message'],
      order['last_message'],
      order['last_message_text'],
      order['message_preview'],
    ]);
    final effectivePreview =
        preview.isNotEmpty ? preview : 'No messages yet. Tap to start.';
    final key = _extractDriverGroupKeyFromOrder(order, driverName);
    final existing = grouped[key];
    if (existing == null) {
      grouped[key] = DriverOrderThread(
        orderId: orderId,
        relatedOrderIds: [orderId],
        driverName: driverName,
        driverContact: driverContact,
        transactionId: transactionId,
        orderLabel: orderLabel,
        preview: effectivePreview,
        lastAt: lastAt,
      );
      continue;
    }

    final mergedIds = <int>{...existing.relatedOrderIds, existing.orderId, orderId}.toList();
    final existingAt = existing.lastAt;
    final takeNewer = existingAt == null || (lastAt != null && lastAt.isAfter(existingAt));
    grouped[key] = DriverOrderThread(
      orderId: takeNewer ? orderId : existing.orderId,
      relatedOrderIds: mergedIds,
      driverName: existing.driverName.isNotEmpty ? existing.driverName : driverName,
      driverContact: existing.driverContact.isNotEmpty ? existing.driverContact : driverContact,
      transactionId: takeNewer ? transactionId : existing.transactionId,
      orderLabel: takeNewer ? orderLabel : existing.orderLabel,
      preview: takeNewer ? effectivePreview : existing.preview,
      lastAt: takeNewer ? lastAt : existing.lastAt,
    );
  }

  final threads = grouped.values.toList();
  threads.sort((a, b) {
    final aAt = a.lastAt;
    final bAt = b.lastAt;
    if (aAt == null && bAt == null) return b.orderId.compareTo(a.orderId);
    if (aAt == null) return 1;
    if (bAt == null) return -1;
    return bAt.compareTo(aAt);
  });

  return threads;
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
  List<DriverOrderThread> _driverThreads = [];
  bool _driverLoading = true;
  String? _driverError;
  bool _chatRefreshInFlight = false;
  bool _driverRefreshInFlight = false;

  @override
  void initState() {
    super.initState();
    _loadChatSummary();
    _loadDriverThreads();
  }

  @override
  void dispose() {
    super.dispose();
  }

  bool _isSameSummary(ChatSummary? a, ChatSummary? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.unreadCount != b.unreadCount) return false;
    final aLast = a.lastMessage;
    final bLast = b.lastMessage;
    if (aLast == null && bLast == null) return true;
    if (aLast == null || bLast == null) return false;
    return aLast.id == bLast.id &&
        aLast.body == bLast.body &&
        aLast.imageUrl == bLast.imageUrl &&
        aLast.createdAt == bLast.createdAt;
  }

  bool _isSameDriverThreads(List<DriverOrderThread> a, List<DriverOrderThread> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      final x = a[i];
      final y = b[i];
      if (x.orderId != y.orderId ||
          x.driverName != y.driverName ||
          x.transactionId != y.transactionId ||
          x.orderLabel != y.orderLabel ||
          x.preview != y.preview ||
          x.lastAt != y.lastAt) {
        return false;
      }
    }
    return true;
  }

  /// Initial load: shows loading indicator.
  Future<void> _loadChatSummary() async {
    if (_chatRefreshInFlight) return;
    _chatRefreshInFlight = true;
    setState(() {
      _chatLoading = true;
      _chatError = null;
    });
    try {
      final summary = await fetchChatSummary();
      if (mounted) {
        final changed = !_isSameSummary(_chatSummary, summary);
        if (changed || _chatLoading || _chatError != null) {
          setState(() {
            _chatSummary = summary;
            _chatLoading = false;
            _chatError = null;
          });
        } else {
          _chatLoading = false;
          _chatError = null;
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _chatLoading = false;
          _chatError = e.toString();
        });
      }
    } finally {
      _chatRefreshInFlight = false;
    }
  }

  /// Real-time background refresh: no loading spinner, only updates data when changed.
  Future<void> _refreshChatSummarySilent() async {
    if (_chatRefreshInFlight) return;
    _chatRefreshInFlight = true;
    try {
      final summary = await fetchChatSummary();
      if (mounted) {
        final changed = !_isSameSummary(_chatSummary, summary);
        if (changed || _chatError != null) {
          setState(() {
            _chatSummary = summary;
            _chatError = null;
          });
        }
      }
    } catch (_) {
      // Keep previous state on silent refresh failure
    } finally {
      _chatRefreshInFlight = false;
    }
  }

  Future<void> _loadDriverThreads() async {
    if (_driverRefreshInFlight) return;
    _driverRefreshInFlight = true;
    setState(() {
      _driverLoading = true;
      _driverError = null;
    });
    try {
      final threads = await fetchDriverOrderThreads();
      if (mounted) {
        final changed = !_isSameDriverThreads(_driverThreads, threads);
        if (changed || _driverLoading || _driverError != null) {
          setState(() {
            _driverThreads = threads;
            _driverLoading = false;
            _driverError = null;
          });
        } else {
          _driverLoading = false;
          _driverError = null;
        }
      }
      _hydrateDriverThreadLatestMessages();
    } catch (e) {
      if (mounted) {
        setState(() {
          _driverLoading = false;
          _driverError = e.toString();
        });
      }
    } finally {
      _driverRefreshInFlight = false;
    }
  }

  Future<void> _hydrateDriverThreadLatestMessages() async {
    if (!mounted) return;
    final current = List<DriverOrderThread>.from(_driverThreads);
    if (current.isEmpty) return;

    // Limit calls to keep the page responsive on large lists.
    final targets = current.where((t) => t.orderId > 0).take(10).toList();
    if (targets.isEmpty) return;
    final latestByOrder = <int, OrderMessageItem>{};

    await Future.wait(targets.map((t) async {
      // Backend returns ascending by created_at, so fetch a page and take the last item as newest.
      final latest = await fetchOrderMessages(orderId: t.orderId, perPage: 100);
      if (latest != null && latest.isNotEmpty) {
        latestByOrder[t.orderId] = latest.last;
      }
    }));

    if (!mounted || latestByOrder.isEmpty) return;
    final updated = current.map((t) {
      final latest = latestByOrder[t.orderId];
      if (latest == null) return t;
      final msg = latest.message.trim();
      return t.copyWith(
        preview: msg.isNotEmpty ? msg : (t.preview ?? 'No messages yet. Tap to start.'),
        lastAt: latest.createdAt ?? t.lastAt,
      );
    }).toList();

    final changed = !_isSameDriverThreads(_driverThreads, updated);
    if (changed && mounted) {
      setState(() => _driverThreads = updated);
    }
  }

  Future<void> _refreshDriverThreadsSilent() async {
    if (_driverRefreshInFlight) return;
    _driverRefreshInFlight = true;
    try {
      final threads = await fetchDriverOrderThreads();
      if (mounted) {
        final changed = !_isSameDriverThreads(_driverThreads, threads);
        if (changed || _driverError != null) {
          setState(() {
            _driverThreads = threads;
            _driverError = null;
          });
        }
      }
    } catch (_) {
    } finally {
      _driverRefreshInFlight = false;
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
                    await Future.wait<void>([
                      _loadChatSummary(),
                      _loadDriverThreads(),
                    ]);
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
                        if (_chatSummary?.lastMessage != null ||
                            (_chatSummary?.unreadCount ?? 0) > 0)
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
                              message: _chatSummary?.lastMessage?.body ??
                                  (((_chatSummary?.unreadCount ?? 0) > 0)
                                      ? 'You have new messages.'
                                      : 'Image'),
                              time: _chatSummary?.lastMessage != null
                                  ? formatMessageTimeAgo(
                                      _chatSummary!.lastMessage!.createdAt,
                                    )
                                  : '',
                            ),
                          ),
                      const SizedBox(height: 10),
                      if (_driverLoading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                        )
                      else if (_driverError != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Column(
                            children: [
                              Text(
                                _driverError!,
                                style: const TextStyle(color: Colors.red),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: _loadDriverThreads,
                                child: const Text('Retry Driver Chats'),
                              ),
                            ],
                          ),
                        )
                      else if (_driverThreads.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.only(bottom: 6),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Driver Chats',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1C1B1F),
                              ),
                            ),
                          ),
                        ),
                        ..._driverThreads.map((thread) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: GestureDetector(
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => DriverOrderChatPage(
                                        orderId: thread.orderId,
                                        relatedOrderIds: thread.relatedOrderIds,
                                        driverName: thread.driverName,
                                        driverContact: thread.driverContact,
                                        orderLabel: thread.orderLabel,
                                      ),
                                    ),
                                  );
                                  if (mounted) _refreshDriverThreadsSilent();
                                },
                                child: messageCard(
                                  icon: Icons.person,
                                  name: thread.driverName,
                                  message: thread.preview ?? 'No messages yet. Tap to start.',
                                  time: thread.lastAt != null
                                      ? formatMessageTimeAgo(thread.lastAt!)
                                      : '',
                                ),
                              ),
                            )),
                      ],
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

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<ChatMessageItem> _messages = [];
  bool _loading = true;
  String? _error;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadMessages();
    markChatRead();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _loadMessages();
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

class DriverOrderChatPage extends StatefulWidget {
  final int orderId;
  final List<int>? relatedOrderIds;
  final String driverName;
  final String driverContact;
  final String orderLabel;

  const DriverOrderChatPage({
    super.key,
    required this.orderId,
    this.relatedOrderIds,
    required this.driverName,
    this.driverContact = '',
    required this.orderLabel,
  });

  @override
  State<DriverOrderChatPage> createState() => _DriverOrderChatPageState();
}

class _DriverOrderChatPageState extends State<DriverOrderChatPage>
    with WidgetsBindingObserver {
  static const double avatarRadius = 22;

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<OrderMessageItem> _messages = [];
  bool _loading = true;
  String? _error;
  bool _sending = false;
  int _activeOrderId = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _activeOrderId = widget.orderId;
    _loadMessages();
    _markAllRelatedMessagesRead();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _loadMessages();
    }
  }

  List<int> get _orderIds {
    final raw = widget.relatedOrderIds ?? <int>[widget.orderId];
    final set = <int>{};
    for (final id in raw) {
      if (id > 0) set.add(id);
    }
    if (set.isEmpty) set.add(widget.orderId);
    return set.toList();
  }

  Future<void> _markAllRelatedMessagesRead() async {
    for (final id in _orderIds) {
      await markOrderMessagesRead(orderId: id);
    }
  }

  Future<List<OrderMessageItem>> _fetchMessagesForOrder(int orderId) async {
    final list = await fetchOrderMessages(orderId: orderId, perPage: 100);
    return list ?? <OrderMessageItem>[];
  }

  List<OrderMessageItem> _sortMergedMessages(List<OrderMessageItem> input) {
    input.sort((a, b) {
      final aAt = a.createdAt;
      final bAt = b.createdAt;
      if (aAt == null && bAt == null) return a.id.compareTo(b.id);
      if (aAt == null) return -1;
      if (bAt == null) return 1;
      final cmp = aAt.compareTo(bAt);
      if (cmp != 0) return cmp;
      return a.id.compareTo(b.id);
    });
    return input;
  }

  Future<void> _loadMessages() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final merged = <OrderMessageItem>[];
      for (final id in _orderIds) {
        merged.addAll(await _fetchMessagesForOrder(id));
      }
      final list = _sortMergedMessages(merged);
      if (mounted) {
        setState(() {
          _messages = list;
          if (list.isNotEmpty) {
            final latest = list.last;
            _activeOrderId = latest.orderId > 0 ? latest.orderId : widget.orderId;
          }
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
      final sendOrderId = _activeOrderId > 0 ? _activeOrderId : widget.orderId;
      final sent = await sendOrderMessage(orderId: sendOrderId, message: text);
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

  Widget _buildMessageBubble(OrderMessageItem m) {
    final isCustomer = m.isMine || m.senderType == _senderCustomer;
    final timeStr = formatMessageTime(m.createdAt ?? DateTime.now());

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
                      Symbols.person,
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
                      color: isCustomer ? const Color(0xFFE3001B) : const Color(0xFFEAEAEA),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      m.message,
                      style: TextStyle(
                        fontWeight: FontWeight.w400,
                        color: isCustomer ? Colors.white : Colors.black,
                      ),
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
                style: const TextStyle(fontSize: 11, color: Color(0xFF1C1B1F)),
              ),
            ),
          ],
        ),
      ),
    );
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.driverName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.driverContact.isNotEmpty
                              ? widget.driverContact
                              : widget.orderLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ],
                    ),
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
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Row(
                        children: [
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
}
