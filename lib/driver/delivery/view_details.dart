import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ice_cream/auth.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeliveryViewDetailsPage extends StatefulWidget {
  final int? shipmentId;
  final Map<String, dynamic>? initialShipment;

  const DeliveryViewDetailsPage({
    super.key,
    this.shipmentId,
    this.initialShipment,
  });

  @override
  State<DeliveryViewDetailsPage> createState() => _DeliveryViewDetailsPageState();
}

class _DeliveryViewDetailsPageState extends State<DeliveryViewDetailsPage> {
  bool _loading = true;
  String _error = '';
  Map<String, dynamic>? _shipment;

  @override
  void initState() {
    super.initState();
    _shipment = widget.initialShipment;
    _loadShipment();
  }

  int? get _shipmentId {
    final fromWidget = widget.shipmentId;
    if (fromWidget != null) return fromWidget;
    final id = _shipment?['id'];
    if (id is int) return id;
    return int.tryParse(id?.toString() ?? '');
  }

  String _fmtMoney(dynamic value) {
    if (value == null) return '₱0';
    final s = value.toString();
    if (s.toUpperCase().startsWith('PHP ')) return '₱${s.substring(4)}';
    final n = value is num ? value.toDouble() : double.tryParse(s);
    if (n == null) return s;
    return '₱${n.toStringAsFixed(n.truncateToDouble() == n ? 0 : 2)}';
  }

  Future<String?> _token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('driver_token');
  }

  Future<void> _loadShipment() async {
    final id = _shipmentId;
    if (id == null) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Shipment ID is missing.';
      });
      return;
    }
    try {
      final token = await _token();
      if (token == null || token.isEmpty) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _error = 'Missing driver session. Please login again.';
        });
        return;
      }
      final res = await http.get(
        Uri.parse('${Auth.apiBaseUrl}/driver/shipments/$id'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (!mounted) return;
      if (res.statusCode == 200 && data['success'] == true && data['shipment'] is Map) {
        setState(() {
          _shipment = Map<String, dynamic>.from(data['shipment'] as Map);
          _loading = false;
          _error = '';
        });
      } else {
        setState(() {
          _loading = false;
          _error = (data['message'] ?? 'Could not load shipment.').toString();
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load shipment. Check connection.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color kText = Color(0xFF111111);
    const Color kMuted = Color(0xFF606060);
    final imageUrl = (_shipment?['proof_image_url'] ?? _shipment?['proof_image'] ?? '')
        .toString();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F6F6),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Symbols.arrow_back,
            color: kText,
            fill: 1,
            weight: 300,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_loading)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
            if (_error.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  _error,
                  style: const TextStyle(
                    color: Color(0xFFE3001B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: _TopMeta(
                    title: (_shipment?['expected_on'] ?? '—').toString(),
                    subtitle: 'Delivered',
                    titleFontSize: 26,
                    subtitleFontSize: 13,
                  ),
                ),
                Expanded(
                  child: _TopMeta(
                    title: (_shipment?['delivered_time'] ?? _shipment?['time'] ?? '—')
                        .toString(),
                    subtitle: 'Time',
                    titleFontSize: 26,
                    subtitleFontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: _TransactionBadge(
                    transactionId: (_shipment?['transaction_label'] ??
                            _shipment?['transaction_id'] ??
                            '—')
                        .toString(),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: _TopMeta(
                    title: '—',
                    subtitle: 'Distance',
                    titleFontSize: 18,
                    subtitleFontSize: 12,
                  ),
                ),
                const Expanded(
                  child: _TopMeta(
                    title: '—',
                    subtitle: 'Travel time',
                    titleFontSize: 18,
                    subtitleFontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              height: 1,
              color: const Color(0xFFD9D9D9),
            ),
            const SizedBox(height: 10),
            const Text(
              'Customer',
              style: TextStyle(
                color: kMuted,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              (_shipment?['customer_name'] ?? '—').toString(),
              style: const TextStyle(
                color: kText,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Delivered address:',
              style: TextStyle(
                color: kMuted,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              (_shipment?['delivery_address'] ?? _shipment?['location'] ?? '—').toString(),
              style: const TextStyle(
                color: kText,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEFEFEF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _InfoRow(label: 'Quantity:', value: (_shipment?['quantity'] ?? '1').toString()),
                  _InfoRow(label: 'Gallon:', value: (_shipment?['size'] ?? '—').toString()),
                  _InfoRow(
                    label: 'Flavor:',
                    value: (_shipment?['order_name'] ?? _shipment?['product_name'] ?? '—')
                        .toString(),
                  ),
                  _InfoRow(
                    label: 'Flavor Type:',
                    value: (_shipment?['order_type'] ?? '—').toString(),
                  ),
                  _InfoRow(
                    label: 'Cost:',
                    value: _fmtMoney(_shipment?['cost_text'] ?? _shipment?['cost']),
                  ),
                  _InfoRow(
                    label: 'Amount:',
                    value: _fmtMoney(_shipment?['amount_text'] ?? _shipment?['amount']),
                  ),
                  _InfoRow(
                    label: 'Customer Number:',
                    value: (_shipment?['customer_phone'] ?? '—').toString(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Proof of Delivery:',
              style: TextStyle(
                color: kText,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: imageUrl.isNotEmpty && imageUrl.startsWith('http')
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: const Color(0xFFE1E1E1),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.image_outlined,
                            color: Color(0xFF8B8B8B),
                            size: 34,
                          ),
                        ),
                      )
                    : Container(
                        color: const Color(0xFFE1E1E1),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.image_outlined,
                          color: Color(0xFF8B8B8B),
                          size: 34,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopMeta extends StatelessWidget {
  const _TopMeta({
    required this.title,
    required this.subtitle,
    this.titleFontSize = 26,
    this.subtitleFontSize = 13,
  });

  final String title;
  final String subtitle;
  final double titleFontSize;
  final double subtitleFontSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: const Color(0xFF111111),
            fontSize: titleFontSize,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          subtitle,
          style: TextStyle(
            color: const Color(0xFF606060),
            fontSize: subtitleFontSize,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _TransactionBadge extends StatelessWidget {
  final String transactionId;

  const _TransactionBadge({required this.transactionId});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFEFEFEF),
            ),
            child: const Icon(
              Symbols.deployed_code,
              color: Color(0xFF2A2A2A),
              size: 20,
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                transactionId,
                style: const TextStyle(
                  color: Color(0xFF111111),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Text(
                'Transaction ID',
                style: TextStyle(
                  color: Color(0xFF606060),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF606060),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF111111),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
