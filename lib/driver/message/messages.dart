import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ice_cream/auth.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'archive_messages.dart';

class messagesPage extends StatefulWidget {
  final int? initialShipmentId;
  final String? initialCustomerName;
  final String? initialCustomerPhone;

  const messagesPage({
    super.key,
    this.initialShipmentId,
    this.initialCustomerName,
    this.initialCustomerPhone,
  });

  @override
  State<messagesPage> createState() => _messagesPageState();
}

class _messagesPageState extends State<messagesPage> {
  bool _loading = true;
  String _error = '';
  List<Map<String, dynamic>> _threads = [];

  @override
  void initState() {
    super.initState();
    _fetchThreads();
  }

  Future<String?> _token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('driver_token');
  }

  Future<List<Map<String, dynamic>>> _fetchShipmentsTab(
    String tab,
    String token,
  ) async {
    final uri = Uri.parse('${Auth.apiBaseUrl}/driver/shipments')
        .replace(queryParameters: {'tab': tab});
    final res = await http.get(
      uri,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200 || data['success'] != true) return [];
    final raw = data['shipments'];
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  DateTime? _parseDateTime(dynamic value) {
    final raw = value?.toString();
    if (raw == null || raw.trim().isEmpty) return null;
    return DateTime.tryParse(raw)?.toLocal();
  }

  Future<Map<String, dynamic>?> _fetchLastMessagePreview({
    required int shipmentId,
    required String token,
  }) async {
    try {
      final res = await http.get(
        Uri.parse('${Auth.apiBaseUrl}/driver/shipments/$shipmentId/messages'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final list = data['data'];
      if (res.statusCode != 200 || data['success'] != true || list is! List || list.isEmpty) {
        return null;
      }
      final latest = list.last;
      if (latest is! Map) return null;
      final msg = (latest['message'] ?? '').toString().trim();
      if (msg.isEmpty) return null;
      return {
        'message': msg,
        'created_at': latest['created_at'],
      };
    } catch (_) {
      return null;
    }
  }

  Future<void> _fetchThreads() async {
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final token = await _token();
      if (token == null || token.isEmpty) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _error = 'Missing driver session. Please login again.';
          _threads = [];
        });
        return;
      }

      final all = <Map<String, dynamic>>[];
      final tabs = ['incoming', 'accepted', 'completed'];
      for (final tab in tabs) {
        all.addAll(await _fetchShipmentsTab(tab, token));
      }

      final byId = <int, Map<String, dynamic>>{};
      for (final shipment in all) {
        final idRaw = shipment['id'];
        final id = idRaw is int ? idRaw : int.tryParse(idRaw?.toString() ?? '');
        if (id == null) continue;
        byId[id] = shipment;
      }

      final list = byId.entries.map((e) {
        final shipment = e.value;
        return <String, dynamic>{
          'shipment_id': e.key,
          'customer_name': (shipment['customer_name'] ?? 'Customer').toString(),
          'customer_phone': (shipment['customer_phone'] ?? '').toString(),
          'delivery_address': (shipment['delivery_address'] ?? shipment['location'] ?? '').toString(),
          'expected_on': (shipment['expected_on'] ?? '').toString(),
          'status_driver': (shipment['status_driver'] ?? '').toString(),
        };
      }).toList();

      final filtered = <Map<String, dynamic>>[];
      for (final item in list) {
        final id = item['shipment_id'] as int;
        final preview = await _fetchLastMessagePreview(shipmentId: id, token: token);
        if (preview == null) continue;
        item['last_message'] = (preview['message'] ?? '').toString();
        item['last_message_at'] = preview['created_at'];
        filtered.add(item);
      }

      // Merge threads by same customer so conversation continues in one chat.
      final grouped = <String, Map<String, dynamic>>{};
      for (final item in filtered) {
        final phone = (item['customer_phone'] ?? '').toString().trim();
        final name = (item['customer_name'] ?? 'Customer').toString().trim().toLowerCase();
        final key = phone.isNotEmpty ? 'p:$phone' : 'n:$name';
        final itemShipmentId = item['shipment_id'] as int;
        final itemAt = _parseDateTime(item['last_message_at']);

        if (!grouped.containsKey(key)) {
          grouped[key] = {
            ...item,
            'shipment_ids': <int>[itemShipmentId],
          };
          continue;
        }

        final current = grouped[key]!;
        final currentAt = _parseDateTime(current['last_message_at']);
        final currentIds = List<int>.from(current['shipment_ids'] as List<int>);
        if (!currentIds.contains(itemShipmentId)) currentIds.add(itemShipmentId);
        current['shipment_ids'] = currentIds;

        final takeNewer = currentAt == null ||
            (itemAt != null && itemAt.isAfter(currentAt));
        if (takeNewer) {
          current['shipment_id'] = itemShipmentId;
          current['delivery_address'] = item['delivery_address'];
          current['expected_on'] = item['expected_on'];
          current['status_driver'] = item['status_driver'];
          current['last_message'] = item['last_message'];
          current['last_message_at'] = item['last_message_at'];
        }
      }

      final merged = grouped.values.toList();
      merged.sort((a, b) {
        final aId = a['shipment_id'] as int;
        final bId = b['shipment_id'] as int;
        final aAt = _parseDateTime(a['last_message_at']);
        final bAt = _parseDateTime(b['last_message_at']);

        if (widget.initialShipmentId != null) {
          final aIds = List<int>.from((a['shipment_ids'] as List?) ?? const []);
          final bIds = List<int>.from((b['shipment_ids'] as List?) ?? const []);
          if (aIds.contains(widget.initialShipmentId) || aId == widget.initialShipmentId) {
            return -1;
          }
          if (bIds.contains(widget.initialShipmentId) || bId == widget.initialShipmentId) {
            return 1;
          }
        }

        if (aAt == null && bAt == null) return bId.compareTo(aId);
        if (aAt == null) return 1;
        if (bAt == null) return -1;
        return bAt.compareTo(aAt);
      });

      if (!mounted) return;
      setState(() {
        _threads = merged;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _threads = [];
        _error = 'Could not load messages. Check connection.';
      });
    }
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  const Text(
                    'Messages',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1C1B1F),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: _fetchThreads,
                    icon: const Icon(Symbols.refresh, size: 22, color: Color(0xFF1C1B1F)),
                  ),
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ArchiveMessagesPage(),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: const SizedBox(
                      width: 44,
                      height: 44,
                      child: Icon(
                        Symbols.archive,
                        size: 22,
                        color: Color(0xFF1C1B1F),
                        fill: 0,
                        weight: 600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
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
                                  onPressed: _fetchThreads,
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : _threads.isEmpty
                          ? const Center(
                              child: Text(
                                'No active message threads.',
                                style: TextStyle(color: Color(0xFF666666)),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              itemCount: _threads.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 10),
                              itemBuilder: (_, index) {
                                final thread = _threads[index];
                                final shipmentId = thread['shipment_id'] as int;
                                final shipmentIds = (thread['shipment_ids'] as List?)
                                        ?.map((e) => int.tryParse(e.toString()))
                                        .whereType<int>()
                                        .toList() ??
                                    <int>[shipmentId];
                                final name = (thread['customer_name'] ?? 'Customer').toString();
                                final phone = (thread['customer_phone'] ?? '').toString();
                                final preview = (thread['last_message'] ?? '').toString();
                                final subtitle = (thread['delivery_address'] ?? '').toString();
                                return GestureDetector(
                                  onTap: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ChatPage(
                                          shipmentId: shipmentId,
                                          relatedShipmentIds: shipmentIds,
                                          customerName: name,
                                          customerPhone: phone,
                                        ),
                                      ),
                                    );
                                    _fetchThreads();
                                  },
                                  child: _MessageCard(
                                    icon: Symbols.person,
                                    name: name,
                                    message: preview,
                                    time: subtitle.isEmpty ? 'Shipment #$shipmentId' : subtitle,
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({
    required this.icon,
    required this.name,
    required this.message,
    required this.time,
  });

  final IconData icon;
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
          Transform.translate(
            offset: const Offset(-4, 0),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                color: Color(0xFFFFE7EA),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 22,
                color: const Color(0xFFE3001B),
                fill: 1,
                weight: 600,
                grade: 200,
                opticalSize: 24,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF1C1B1F),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  time,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF616161)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ChatPage extends StatefulWidget {
  final int shipmentId;
  final List<int>? relatedShipmentIds;
  final String customerName;
  final String? customerPhone;

  const ChatPage({
    super.key,
    required this.shipmentId,
    this.relatedShipmentIds,
    required this.customerName,
    this.customerPhone,
  });

  static const double avatarRadius = 22;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  bool _loading = true;
  bool _sending = false;
  String _error = '';
  List<_OrderMessage> _messages = [];
  int _activeShipmentId = 0;

  @override
  void initState() {
    super.initState();
    _activeShipmentId = widget.shipmentId;
    _loadMessages();
    _markRead();
  }

  @override
  void dispose() {
    _messageCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

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

  List<int> get _shipmentIds {
    final raw = widget.relatedShipmentIds ?? <int>[widget.shipmentId];
    final set = <int>{};
    for (final id in raw) {
      if (id > 0) set.add(id);
    }
    if (set.isEmpty) set.add(widget.shipmentId);
    return set.toList();
  }

  Future<List<_OrderMessage>> _fetchMessagesForShipment({
    required int shipmentId,
    required String token,
  }) async {
    final res = await http.get(
      Uri.parse('${Auth.apiBaseUrl}/driver/shipments/$shipmentId/messages'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200 || data['success'] != true || data['data'] is! List) {
      return <_OrderMessage>[];
    }
    return (data['data'] as List)
        .whereType<Map>()
        .map((raw) => _OrderMessage.fromMap(Map<String, dynamic>.from(raw)))
        .toList();
  }

  Future<void> _loadMessages({bool showLoader = true}) async {
    if (showLoader) {
      setState(() {
        _loading = true;
        _error = '';
      });
    }
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
      final shipmentIds = _shipmentIds;
      final merged = <_OrderMessage>[];
      for (final id in shipmentIds) {
        merged.addAll(await _fetchMessagesForShipment(shipmentId: id, token: token));
      }
      if (!mounted) return;
      if (merged.isNotEmpty) {
        merged.sort((a, b) {
          final aAt = a.createdAt;
          final bAt = b.createdAt;
          if (aAt == null && bAt == null) return a.id.compareTo(b.id);
          if (aAt == null) return -1;
          if (bAt == null) return 1;
          final timeCmp = aAt.compareTo(bAt);
          if (timeCmp != 0) return timeCmp;
          return a.id.compareTo(b.id);
        });
        final latest = merged.last;
        setState(() {
          _messages = merged;
          _activeShipmentId = latest.orderId > 0 ? latest.orderId : widget.shipmentId;
          _loading = false;
          _error = '';
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!_scrollCtrl.hasClients) return;
          _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
        });
      } else {
        setState(() {
          _messages = [];
          _loading = false;
          _error = '';
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load messages. Check connection.';
      });
    }
  }

  Future<void> _markRead() async {
    try {
      final token = await _token();
      if (token == null || token.isEmpty) return;
      for (final id in _shipmentIds) {
        await http.post(
          Uri.parse('${Auth.apiBaseUrl}/driver/shipments/$id/messages/read'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
      }
    } catch (_) {}
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
      final sendShipmentId = _activeShipmentId > 0 ? _activeShipmentId : widget.shipmentId;
      final res = await http.post(
        Uri.parse('${Auth.apiBaseUrl}/driver/shipments/$sendShipmentId/messages'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'message': text}),
      );
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (!mounted) return;
      if ((res.statusCode == 201 || res.statusCode == 200) && data['success'] == true) {
        _messageCtrl.clear();
        await _loadMessages(showLoader: false);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text((data['message'] ?? 'Could not send message.').toString())),
        );
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
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
                    radius: ChatPage.avatarRadius,
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
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          (widget.customerPhone ?? '').isEmpty
                              ? 'Shipment #${widget.shipmentId}'
                              : widget.customerPhone!,
                          style: const TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _loadMessages(showLoader: false),
                    icon: const Icon(Symbols.refresh),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
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
                                const SizedBox(height: 10),
                                ElevatedButton(
                                  onPressed: () => _loadMessages(),
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollCtrl,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final item = _messages[index];
                            final mine = item.isMine;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Align(
                                alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                                child: Column(
                                  crossAxisAlignment: mine
                                      ? CrossAxisAlignment.end
                                      : CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      constraints: const BoxConstraints(maxWidth: 280),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 15,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: mine
                                            ? const Color(0xFFE3001B)
                                            : const Color(0xFFEAEAEA),
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                      child: Text(
                                        item.message,
                                        style: TextStyle(
                                          color: mine ? Colors.white : const Color(0xFF1C1B1F),
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _formatTime(item.createdAt),
                                      style: const TextStyle(fontSize: 11, color: Color(0xFF666666)),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
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

class _OrderMessage {
  final int id;
  final int orderId;
  final String senderType;
  final String message;
  final bool isMine;
  final DateTime? createdAt;

  const _OrderMessage({
    required this.id,
    required this.orderId,
    required this.senderType,
    required this.message,
    required this.isMine,
    required this.createdAt,
  });

  factory _OrderMessage.fromMap(Map<String, dynamic> json) {
    final idRaw = json['id'];
    final orderIdRaw = json['order_id'];
    final createdAtRaw = json['created_at']?.toString();
    return _OrderMessage(
      id: idRaw is int ? idRaw : int.tryParse(idRaw?.toString() ?? '') ?? 0,
      orderId: orderIdRaw is int ? orderIdRaw : int.tryParse(orderIdRaw?.toString() ?? '') ?? 0,
      senderType: (json['sender_type'] ?? '').toString(),
      message: (json['message'] ?? '').toString(),
      isMine: json['is_mine'] == true,
      createdAt: createdAtRaw == null ? null : DateTime.tryParse(createdAtRaw)?.toLocal(),
    );
  }
}
