import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:ice_cream/client/messages/messages.dart';
import 'package:ice_cream/client/order/order_record.dart';
import 'package:ice_cream/auth.dart';
import 'package:http/http.dart' as http;
import 'package:material_symbols_icons/material_symbols_icons.dart';

class DeliveryTrackerPage extends StatefulWidget {
  const DeliveryTrackerPage({super.key, required this.order});

  final OrderRecord order;

  @override
  State<DeliveryTrackerPage> createState() => _DeliveryTrackerPageState();
}

class _DeliveryTrackerPageState extends State<DeliveryTrackerPage> {
  late OrderRecord _order = widget.order;
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    // Best-effort refresh so status/date stay up to date.
    _refreshOrder();
  }

  Future<void> _refreshOrder() async {
    final token = await Auth.getToken();
    if (!mounted || token == null || token.isEmpty) return;
    setState(() => _refreshing = true);
    try {
      final uri = Uri.parse('${Auth.apiBaseUrl}/orders/${widget.order.id}');
      final res = await http.get(
        uri,
        headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
      );
      if (!mounted) return;
      final body = jsonDecode(res.body) as Map<String, dynamic>?;
      if (res.statusCode == 200) {
        final data = body?['data'] as Map<String, dynamic>?;
        if (data != null) setState(() => _order = OrderRecord.fromJson(data));
      }
    } catch (_) {
      // Ignore refresh errors; we still show the passed-in order data.
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  String get _etaLabel {
    final date = _order.deliveryDate;
    final time = _order.deliveryTime;
    if ((date == null || date.isEmpty) && (time == null || time.isEmpty)) return 'Estimated on: —';
    if (date == null || date.isEmpty) return 'Estimated on: —, $time';
    if (time == null || time.isEmpty) return 'Estimated on: $date';
    return 'Estimated on: $date, $time';
  }

  String get _statusLabel {
    switch (_order.status) {
      case 'pending':
        return 'Pending';
      case 'assigned':
        return 'Assigned';
      case 'driving':
      case 'on_the_way':
        return 'Driving';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      case 'walk_in':
        return 'Walk-in';
      default:
        final s = _order.status.trim();
        if (s.isEmpty) return '—';
        return s[0].toUpperCase() + s.substring(1);
    }
  }

  Color get _statusColor {
    switch (_order.status) {
      case 'delivered':
      case 'walk_in':
        return const Color(0xFF22B345);
      case 'cancelled':
        return const Color(0xFFE3001B);
      case 'pending':
      case 'assigned':
        return const Color(0xFFFF6805);
      default:
        return const Color(0xFF7051C7);
    }
  }

  @override
  Widget build(BuildContext context) {
    const double mapTop = 30;
    const double mapHeight = 300;

    return Scaffold(
      body: Stack(
        children: [
          // Map background
          Positioned(
            top: mapTop,
            left: 0,
            right: 0,
            height: mapHeight,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.asset(
                'lib/client/order/images/map.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          // X (close) button - top right of map
          Positioned(
            top: mapTop + 12,
            right: 18,
            child: _mapOverlayButton(
              icon: Icons.close,
              onTap: () => Navigator.of(context).pop(),
            ),
          ),
          // + and - zoom buttons - bottom right of map
          Positioned(
            top: mapTop + mapHeight - 24 - 48 - 20 - 46,
            right: 18,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _mapOverlayButton(icon: Icons.add, onTap: () {}),
                const SizedBox(height: 10),
                _mapOverlayButton(icon: Icons.remove, onTap: () {}),
              ],
            ),
          ),
          // Bottom sheet panel
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height:
                  MediaQuery.of(context).size.height * 0.58, // adjust height
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(25),
                  topRight: Radius.circular(25),
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(25),
                  topRight: Radius.circular(25),
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20, // horizontal padding
                      vertical: 14, // keeps vertical spacing
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Your content here (same as your current Column)
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _etaLabel,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (_refreshing) ...[
                              const SizedBox(width: 10),
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ],
                          ],
                        ),

                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFF2F2F2),
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: Icon(
                                    Symbols.deployed_code,
                                    size: 18,
                                    color: const Color(0xFF1C1B1F),
                                  ),
                                ),
                                const SizedBox(width: 12),

                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '#${_order.transactionId.isEmpty ? '—' : _order.transactionId}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const Text(
                                      'Transaction ID',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w400,
                                        color: Color(0xFF575757),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _statusColor,
                                minimumSize: const Size(
                                  93,
                                  30,
                                ), // <-- width, height
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: Text(
                                _statusLabel,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xFFFFFFFF),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const Divider(height: 12),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // LEFT - Shipped By
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'Driver',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    color: Color(0xFF1C1B1F),
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  '—',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),

                            // CENTER - Order Cost
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(
                                    left: 8,
                                  ), // moves only "Created:" left
                                  child: Text(
                                    'Order Cost',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                      color: Color(0xFF1C1B1F),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _order.amountFormatted,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),

                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(
                                    right: 28,
                                  ), // moves only "Created:" left
                                  child: Text(
                                    'Created',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                      color: Color(0xFF1C1B1F),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _order.createdAtFormatted ?? '—',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _detailRow('Quantity:', '${_order.quantity}'),
                              const SizedBox(height: 3),
                              _detailRow('Size:', _order.gallonSize),
                              const SizedBox(height: 8),
                              _detailRow('Flavor:', _order.productName),
                              const SizedBox(height: 3),
                              _detailRow('Type:', _order.productType.isEmpty ? '—' : _order.productType),
                              const SizedBox(height: 3),
                              _detailRow('Payment method:', _order.paymentMethod ?? '—'),
                              const SizedBox(height: 3),
                              _detailRow('Delivery address:', _order.deliveryAddress ?? '—', valueMaxLines: 2),
                              const SizedBox(height: 3),
                              const _DetailRow(
                                label: 'Contact number:',
                                value: '—',
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 9.5),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // Message Driver button
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => const ChatPage(),
                                    ),
                                  );
                                },
                                child: Container(
                                  height: 55, // same as Check Out
                                  decoration: BoxDecoration(
                                    color: Colors.white, // white background
                                    borderRadius: BorderRadius.circular(
                                      35,
                                    ), // rounded corners
                                    border: Border.all(
                                      color: Color(0xFF8B8B8B),
                                    ), // border color
                                  ),
                                  child: const Center(
                                    child: Text(
                                      "Message Driver",
                                      style: TextStyle(
                                        color: Color(0xFF494949), // text color
                                        fontSize: 16, // same size as Check Out
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(width: 13),

                            // Call icon button
                            Container(
                              height: 55, // same height as button
                              width:
                                  55, // slightly bigger circle like Check Out add icon
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                border: Border.all(color: Color(0xFF8B8B8B)),
                              ),
                              child: const Icon(
                                Icons.call, // updated icon
                                color: Color(0xFF494949),
                                size: 28, // same as add icon
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _detailRow(String label, String value, {int valueMaxLines = 1}) {
  return _DetailRow(label: label, value: value, valueMaxLines: valueMaxLines);
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.valueMaxLines = 1,
  });

  final String label;
  final String value;
  final int valueMaxLines;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: valueMaxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 160,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Color(0xFF606060),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            maxLines: valueMaxLines,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

Widget _mapOverlayButton({
  required IconData icon,
  required VoidCallback onTap,
}) {
  return Material(
    color: Colors.white,
    shape: const CircleBorder(),
    elevation: 2,
    shadowColor: Colors.black.withOpacity(0.2),
    child: InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        child: Icon(icon, color: const Color(0xFF1C1B1F), size: 24),
      ),
    ),
  );
}
