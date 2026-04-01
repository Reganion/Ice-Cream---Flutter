import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:ice_cream/client/messages/messages.dart';
import 'package:ice_cream/client/order/order_record.dart';
import 'package:ice_cream/auth.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:url_launcher/url_launcher.dart';

class DeliveryTrackerPage extends StatefulWidget {
  const DeliveryTrackerPage({super.key, required this.order});

  final OrderRecord order;

  @override
  State<DeliveryTrackerPage> createState() => _DeliveryTrackerPageState();
}

class _DeliveryTrackerPageState extends State<DeliveryTrackerPage> {
  late OrderRecord _order = widget.order;
  int? _driverId;
  String _driverName = '—';
  String _driverPhone = '';
  String _customerContact = '—';
  bool _refreshing = false;
  bool _trackingLoading = false;
  String _trackingError = '';
  final MapController _mapController = MapController();
  double _mapZoom = 15;
  Timer? _trackingTimer;
  LatLng? _driverLocation;
  LatLng? _destinationLocation;
  List<LatLng> _routeHistory = const [];

  void _recenterToTracking({
    required LatLng? latest,
    required LatLng? destination,
    required List<LatLng> history,
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        final points = <LatLng>[
          ...history,
          if (latest != null) latest,
          if (destination != null) destination,
        ];
        if (points.isEmpty) return;
        if (points.length == 1) {
          _mapZoom = 16;
          _mapController.move(points.first, _mapZoom);
          return;
        }
        final bounds = LatLngBounds.fromPoints(points);
        _mapController.fitCamera(
          CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(48)),
        );
      } catch (_) {}
    });
  }

  @override
  void initState() {
    super.initState();
    _refreshOrder();
    _startTrackingPolling();
  }

  @override
  void dispose() {
    _trackingTimer?.cancel();
    super.dispose();
  }

  void _startTrackingPolling() {
    _loadTracking();
    _trackingTimer?.cancel();
    _trackingTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      _loadTracking();
    });
  }

  Future<void> _refreshOrder() async {
    final token = await Auth.getToken();
    if (!mounted || token == null || token.isEmpty) return;
    setState(() => _refreshing = true);
    try {
      final uri = Uri.parse('${Auth.apiBaseUrl}/orders/${widget.order.id}');
      final res = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (!mounted) return;
      final body = jsonDecode(res.body) as Map<String, dynamic>?;
      if (res.statusCode == 200) {
        final data = body?['data'] as Map<String, dynamic>?;
        if (data != null) {
          setState(() {
            _order = OrderRecord.fromJson(data);
            _driverId = _extractDriverId(data);
            _driverName = _extractDriverName(data);
            _driverPhone = _extractDriverPhone(data);
            _customerContact = _extractCustomerContact(data);
          });
        }
      }
    } catch (_) {
      // Ignore refresh errors; we still show the passed-in order data.
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  double? _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse((value ?? '').toString());
  }

  LatLng? _latLngFromMap(dynamic raw) {
    if (raw is! Map) return null;
    final source = Map<String, dynamic>.from(raw);
    final lat = _asDouble(source['lat']);
    final lng = _asDouble(source['lng']);
    if (lat == null || lng == null) return null;
    return LatLng(lat, lng);
  }

  Future<void> _loadTracking() async {
    final token = await Auth.getToken();
    if (!mounted || token == null || token.isEmpty) return;
    setState(() => _trackingLoading = true);
    try {
      final res = await http.get(
        Uri.parse('${Auth.apiBaseUrl}/orders/${_order.id}/tracking'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (!mounted) return;
      final body = jsonDecode(res.body) as Map<String, dynamic>?;
      if (res.statusCode == 200 &&
          body?['success'] == true &&
          body?['tracking'] is Map) {
        final tracking = Map<String, dynamic>.from(body?['tracking'] as Map);
        final latest = _latLngFromMap(tracking['latest']);
        final destination = _latLngFromMap(tracking['destination']);
        final historyRaw = tracking['history'];
        final history = <LatLng>[];
        if (historyRaw is List) {
          for (final point in historyRaw) {
            final parsed = _latLngFromMap(point);
            if (parsed != null) history.add(parsed);
          }
        }
        if (latest != null &&
            (history.isEmpty ||
                history.last.latitude != latest.latitude ||
                history.last.longitude != latest.longitude)) {
          history.add(latest);
        }

        setState(() {
          _driverLocation = latest;
          _destinationLocation = destination;
          _routeHistory = history;
          _trackingError = '';
        });
        _recenterToTracking(
          latest: latest,
          destination: destination,
          history: history,
        );
      } else {
        setState(() {
          _trackingError =
              (body?['message'] ?? 'Tracking is unavailable right now.')
                  .toString();
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _trackingError = 'Could not load tracking map.');
    } finally {
      if (mounted) {
        setState(() => _trackingLoading = false);
      }
    }
  }

  LatLng get _mapCenter {
    return _driverLocation ??
        _destinationLocation ??
        (_routeHistory.isNotEmpty
            ? _routeHistory.last
            : const LatLng(10.3157, 123.8854));
  }

  Widget _buildTrackingMap() {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _mapCenter,
            initialZoom: _mapZoom,
            minZoom: 4,
            maxZoom: 19,
            onPositionChanged: (position, _) {
              _mapZoom = position.zoom;
            },
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.hricecream.app',
            ),
            if (_routeHistory.length > 1)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _routeHistory,
                    strokeWidth: 4,
                    color: const Color(0xFF7051C7),
                  ),
                ],
              ),
            MarkerLayer(
              markers: [
                if (_destinationLocation != null)
                  Marker(
                    point: _destinationLocation!,
                    width: 44,
                    height: 44,
                    child: const Icon(
                      Icons.location_on,
                      size: 40,
                      color: Color(0xFF007CFF),
                    ),
                  ),
                if (_driverLocation != null)
                  Marker(
                    point: _driverLocation!,
                    width: 44,
                    height: 44,
                    child: const Icon(
                      Icons.delivery_dining,
                      size: 38,
                      color: Color(0xFFE3001B),
                    ),
                  ),
              ],
            ),
          ],
        ),
        if (_trackingLoading)
          const Positioned(
            left: 12,
            bottom: 12,
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        if (_trackingError.isNotEmpty)
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.65),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _trackingError,
                style: const TextStyle(color: Colors.white, fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
      ],
    );
  }

  String _pickFirstNonEmpty(List<dynamic> values) {
    for (final v in values) {
      final s = (v ?? '').toString().trim();
      if (s.isNotEmpty) return s;
    }
    return '';
  }

  String _extractDriverName(Map<String, dynamic> order) {
    String fullNameFromParts(Map<String, dynamic> source) {
      final first = _pickFirstNonEmpty([
        source['firstname'],
        source['first_name'],
        source['driver_first_name'],
        source['assigned_driver_first_name'],
        source['rider_first_name'],
      ]);
      final last = _pickFirstNonEmpty([
        source['lastname'],
        source['last_name'],
        source['driver_last_name'],
        source['assigned_driver_last_name'],
        source['rider_last_name'],
      ]);
      return '$first $last'.trim();
    }

    final direct = _pickFirstNonEmpty([
      order['driver_name'],
      order['assigned_driver_name'],
      order['rider_name'],
      order['driver_full_name'],
      order['driver_display_name'],
    ]);
    if (direct.isNotEmpty) return direct;

    final nestedRaw =
        order['driver'] ?? order['assigned_driver'] ?? order['rider'];
    if (nestedRaw is Map) {
      final nested = Map<String, dynamic>.from(nestedRaw);
      final nestedDirect = _pickFirstNonEmpty([
        nested['name'],
        nested['full_name'],
        nested['driver_name'],
        nested['display_name'],
      ]);
      if (nestedDirect.isNotEmpty) return nestedDirect;
      final nestedParts = fullNameFromParts(nested);
      if (nestedParts.isNotEmpty) return nestedParts;
    }

    final topParts = fullNameFromParts(order);
    return topParts.isNotEmpty ? topParts : '—';
  }

  int? _extractDriverId(Map<String, dynamic> order) {
    final direct = order['driver_id'];
    if (direct is int) return direct;
    final fromDirect = int.tryParse((direct ?? '').toString());
    if (fromDirect != null && fromDirect > 0) return fromDirect;
    final nestedRaw =
        order['driver'] ?? order['assigned_driver'] ?? order['rider'];
    if (nestedRaw is Map) {
      final nested = Map<String, dynamic>.from(nestedRaw);
      final nestedId = nested['id'] ?? nested['driver_id'] ?? nested['user_id'];
      if (nestedId is int) return nestedId;
      final parsed = int.tryParse((nestedId ?? '').toString());
      if (parsed != null && parsed > 0) return parsed;
    }
    return null;
  }

  String _extractDriverPhone(Map<String, dynamic> order) {
    final direct = _pickFirstNonEmpty([
      order['driver_phone'],
      order['driver_contact'],
      order['assigned_driver_phone'],
      order['assigned_driver_contact'],
      order['rider_phone'],
      order['rider_contact'],
    ]);
    if (direct.isNotEmpty) return direct;

    final nestedRaw =
        order['driver'] ?? order['assigned_driver'] ?? order['rider'];
    if (nestedRaw is Map) {
      final nested = Map<String, dynamic>.from(nestedRaw);
      final nestedPhone = _pickFirstNonEmpty([
        nested['phone'],
        nested['contact_no'],
        nested['contact_number'],
        nested['mobile'],
        nested['mobile_number'],
      ]);
      if (nestedPhone.isNotEmpty) return nestedPhone;
    }

    return '';
  }

  String _extractCustomerContact(Map<String, dynamic> order) {
    final direct = _pickFirstNonEmpty([
      order['customer_phone'],
      order['customer_contact'],
      order['contact_no'],
      order['contact_number'],
      order['phone'],
      order['mobile'],
    ]);
    if (direct.isNotEmpty) return direct;

    final customerRaw = order['customer'];
    if (customerRaw is Map) {
      final customer = Map<String, dynamic>.from(customerRaw);
      final nested = _pickFirstNonEmpty([
        customer['contact_no'],
        customer['contact_number'],
        customer['customer_phone'],
        customer['phone'],
        customer['mobile'],
      ]);
      if (nested.isNotEmpty) return nested;
    }

    return '—';
  }

  String get _normalizedStatus {
    return _order.status.trim().toLowerCase().replaceAll('_', ' ');
  }

  bool get _isOutForDelivery {
    return _normalizedStatus == 'out of delivery' ||
        _normalizedStatus == 'out for delivery' ||
        _normalizedStatus == 'driving' ||
        _normalizedStatus == 'on the way';
  }

  bool get _canMessageDriver {
    return _isOutForDelivery && _driverId != null && _driverId! > 0;
  }

  Future<void> _openDriverChat() async {
    if (!_canMessageDriver) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'You can only chat the driver when your order is out for delivery.',
          ),
        ),
      );
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DriverOrderChatPage(
          orderId: _order.id,
          relatedOrderIds: <int>[_order.id],
          driverName: _driverName,
          driverContact: _driverPhone,
          orderLabel: _order.productName,
        ),
      ),
    );
  }

  Future<void> _callDriver() async {
    if (!_isOutForDelivery) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Driver call is available once your order is out for delivery.',
          ),
        ),
      );
      return;
    }
    final phone = _driverPhone.trim();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Driver phone number is not available yet.'),
        ),
      );
      return;
    }
    final uri = Uri(scheme: 'tel', path: phone);
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open phone dialer.')),
      );
    }
  }

  String get _etaLabel {
    final date = _order.deliveryDate;
    final time = _order.deliveryTime;
    if ((date == null || date.isEmpty) && (time == null || time.isEmpty))
      return 'Estimated on: —';
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
              child: _buildTrackingMap(),
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
                _mapOverlayButton(
                  icon: Icons.add,
                  onTap: () {
                    _mapZoom = (_mapZoom + 1).clamp(4, 19).toDouble();
                    _mapController.move(_mapCenter, _mapZoom);
                  },
                ),
                const SizedBox(height: 10),
                _mapOverlayButton(
                  icon: Icons.remove,
                  onTap: () {
                    _mapZoom = (_mapZoom - 1).clamp(4, 19).toDouble();
                    _mapController.move(_mapCenter, _mapZoom);
                  },
                ),
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
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
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
                              children: [
                                const Text(
                                  'Driver',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    color: Color(0xFF1C1B1F),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _driverName,
                                  style: const TextStyle(
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
                              _detailRow(
                                'Type:',
                                _order.productType.isEmpty
                                    ? '—'
                                    : _order.productType,
                              ),
                              const SizedBox(height: 3),
                              _detailRow(
                                'Payment method:',
                                _order.paymentMethod ?? '—',
                              ),
                              const SizedBox(height: 3),
                              _detailRow(
                                'Delivery address:',
                                _order.deliveryAddress ?? '—',
                                valueMaxLines: 2,
                              ),
                              const SizedBox(height: 3),
                              _DetailRow(
                                label: 'Contact number:',
                                value: _customerContact,
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
                                onTap: _openDriverChat,
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
                                  child: Center(
                                    child: Text(
                                      "Message Driver",
                                      style: TextStyle(
                                        color: _canMessageDriver
                                            ? const Color(0xFF494949)
                                            : const Color(0xFF9A9A9A),
                                        fontSize: 16, // same size as Check Out
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(width: 13),

                            // Call icon button
                            GestureDetector(
                              onTap: _callDriver,
                              child: Container(
                                height: 55, // same height as button
                                width:
                                    55, // slightly bigger circle like Check Out add icon
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  border: Border.all(
                                    color: const Color(0xFF8B8B8B),
                                  ),
                                ),
                                child: Icon(
                                  Icons.call, // updated icon
                                  color: _isOutForDelivery
                                      ? const Color(0xFF494949)
                                      : const Color(0xFF9A9A9A),
                                  size: 28, // same as add icon
                                ),
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
      crossAxisAlignment: valueMaxLines > 1
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
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
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
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
