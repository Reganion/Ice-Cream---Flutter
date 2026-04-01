import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:ice_cream/auth.dart';
import 'package:ice_cream/driver/delivery/complete_delivery.dart';
import 'package:ice_cream/driver/message/messages.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class ConfirmDeliveryPage extends StatefulWidget {
  /// When true, show only "Deliver now" button (e.g. for Pending shipments already accepted).
  final bool showDeliverNowOnly;
  final int? shipmentId;
  final Map<String, dynamic>? initialShipment;

  const ConfirmDeliveryPage({
    super.key,
    this.showDeliverNowOnly = false,
    this.shipmentId,
    this.initialShipment,
  });

  @override
  State<ConfirmDeliveryPage> createState() => _ConfirmDeliveryPageState();
}

class _ConfirmDeliveryPageState extends State<ConfirmDeliveryPage> {
  late bool _showDeliverNow;
  bool _forceShowFullCard =
      false; // true when user tapped to expand (show full card even before sheet resizes)
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();
  bool _loading = true;
  bool _submitting = false;
  String _error = '';
  Map<String, dynamic>? _shipment;
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
    _showDeliverNow = widget.showDeliverNowOnly;
    _shipment = widget.initialShipment;
    final initialStatusDriver = (_shipment?['status_driver'] ?? '')
        .toString()
        .toLowerCase();
    if (initialStatusDriver == 'accepted' ||
        initialStatusDriver == 'completed') {
      _showDeliverNow = true;
    }
    _sheetController.addListener(_onSheetSizeChange);
    _loadShipment();
    _startTrackingPolling();
  }

  int? get _shipmentId {
    final fromWidget = widget.shipmentId;
    if (fromWidget != null) return fromWidget;
    final id = _shipment?['id'];
    if (id is int) return id;
    return int.tryParse(id?.toString() ?? '');
  }

  /// Normalized order status (lowercase, trimmed).
  String get _orderStatus =>
      (_shipment?['status'] ?? '').toString().trim().toLowerCase();

  /// Deliver now is only allowed when order status is "ready" (not when preparing).
  bool get _canDeliverNow => _showDeliverNow && _orderStatus == 'ready';

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
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Shipment ID is missing.';
        });
      }
      return;
    }
    try {
      final token = await _token();
      if (token == null || token.isEmpty) {
        if (mounted) {
          setState(() {
            _loading = false;
            _error = 'Missing driver session. Please login again.';
          });
        }
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
      if (res.statusCode == 200 &&
          data['success'] == true &&
          data['shipment'] is Map) {
        final s = Map<String, dynamic>.from(data['shipment'] as Map);
        final statusDriver = (s['status_driver'] ?? '')
            .toString()
            .toLowerCase();
        setState(() {
          _shipment = s;
          _loading = false;
          _error = '';
          if (statusDriver == 'accepted' || statusDriver == 'completed') {
            _showDeliverNow = true;
          }
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

  void _startTrackingPolling() {
    _loadTracking();
    _trackingTimer?.cancel();
    _trackingTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      _loadTracking();
    });
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
    final id = _shipmentId;
    if (id == null || !mounted) return;
    final token = await _token();
    if (!mounted || token == null || token.isEmpty) return;
    setState(() => _trackingLoading = true);
    try {
      final res = await http.get(
        Uri.parse('${Auth.apiBaseUrl}/driver/shipments/$id/tracking'),
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
      if (mounted) setState(() => _trackingLoading = false);
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

  Future<bool> _postShipmentAction(String action) async {
    final id = _shipmentId;
    if (id == null || _submitting) return false;
    setState(() => _submitting = true);
    try {
      final token = await _token();
      if (token == null || token.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Missing driver session. Please login again.'),
            ),
          );
        }
        return false;
      }
      final res = await http.post(
        Uri.parse('${Auth.apiBaseUrl}/driver/shipments/$id/$action'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (!mounted) return false;
      if (res.statusCode >= 200 &&
          res.statusCode < 300 &&
          data['success'] == true) {
        return true;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text((data['message'] ?? 'Action failed.').toString()),
        ),
      );
      return false;
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Action failed. Check your connection.'),
          ),
        );
      }
      return false;
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _onSheetSizeChange() {
    if (mounted) {
      if (_sheetController.isAttached && _sheetController.size > 0.2) {
        _forceShowFullCard = false;
      }
      setState(() {});
    }
  }

  void _expandSheet() {
    setState(() => _forceShowFullCard = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_sheetController.isAttached) return;
      _sheetController.animateTo(
        0.74,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  void _collapseSheet() {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final minSize = isLandscape ? 0.18 : 0.11;
    setState(() => _forceShowFullCard = false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_sheetController.isAttached) return;
      _sheetController.animateTo(
        minSize,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  void _openChat() {
    _openChatForCustomer();
  }

  Future<void> _openChatForCustomer() async {
    final id = _shipmentId;
    if (id == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Shipment ID is missing.')));
      return;
    }
    final token = await _token();
    if (token == null || token.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Missing driver session. Please login again.'),
        ),
      );
      return;
    }
    final customerName = (_shipment?['customer_name'] ?? 'Customer').toString();
    final customerPhone = (_shipment?['customer_phone'] ?? '').toString();
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatPage(
          shipmentId: id,
          relatedShipmentIds: [id],
          customerName: customerName,
          customerPhone: customerPhone,
        ),
      ),
    );
  }

  String _phoneDigits(String value) => value.replaceAll(RegExp(r'[^0-9+]'), '');

  Future<void> _openCall() async {
    final raw = (_shipment?['customer_phone'] ?? '').toString().trim();
    final cleaned = _phoneDigits(raw);
    if (cleaned.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Customer phone number is unavailable.')),
      );
      return;
    }
    try {
      final uri = Uri.parse('tel:$cleaned');
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open phone dialer.')),
        );
      }
    } on MissingPluginException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Phone plugin not ready. Please restart app.'),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open phone dialer.')),
      );
    }
  }

  @override
  void dispose() {
    _trackingTimer?.cancel();
    _sheetController.removeListener(_onSheetSizeChange);
    _sheetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Full-screen map (big map when sheet is swiped down)
          Positioned.fill(
            child: Transform.translate(
              offset: const Offset(0, 18),
              child: _buildTrackingMap(),
            ),
          ),

          // Back button on map
          Positioned(
            left: 16,
            top: MediaQuery.of(context).padding.top + 13,
            child: Material(
              shape: const CircleBorder(),
              elevation: 2,
              child: InkWell(
                onTap: () => Navigator.pop(context),
                customBorder: const CircleBorder(),
                child: const SizedBox(
                  width: 46,
                  height: 46,
                  child: Icon(
                    Symbols.arrow_back,
                    size: 24,
                    color: Color(0xFF414141),
                    fill: 1,
                    weight: 200,
                    grade: 200,
                    opticalSize: 24,
                  ),
                ),
              ),
            ),
          ),

          // Scrollable info card
          DraggableScrollableSheet(
            controller: _sheetController,
            // ✅ FIX: landscape needs a taller collapsed height
            minChildSize:
                MediaQuery.of(context).orientation == Orientation.landscape
                ? 0.18
                : 0.11,
            initialChildSize: 0.74,
            maxChildSize: 0.74,
            builder: (context, scrollController) {
              final isLandscape =
                  MediaQuery.of(context).orientation == Orientation.landscape;
              final screenWidth = MediaQuery.of(context).size.width;
              final minSize = isLandscape ? 0.18 : 0.11;
              final isCompact =
                  !isLandscape && MediaQuery.of(context).size.height < 760;
              final detailsHorizontalPadding = screenWidth < 360
                  ? 12.0
                  : screenWidth < 420
                  ? 14.0
                  : 16.0;
              final detailsVerticalPadding = screenWidth < 360
                  ? 10.0
                  : isCompact
                  ? 12.0
                  : 14.0;
              final detailsRadius = screenWidth < 360 ? 14.0 : 16.0;

              // ✅ FIX: collapsed detection based on actual min size (prevents weird states)
              final isCollapsed =
                  _sheetController.isAttached &&
                  _sheetController.size <= (minSize + 0.02);

              final showFullCard = !isCollapsed || _forceShowFullCard;

              return Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(25),
                    topRight: Radius.circular(25),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  // ✅ keeps content above system gesture bar in landscape
                  bottom: true,
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: isCollapsed
                        ? MainAxisAlignment.end
                        : MainAxisAlignment.start,
                    children: [
                      // ✅ FIX: make handle tighter (and optional in collapsed to save height)
                      if (!isCollapsed)
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: _collapseSheet,
                          child: Center(
                            child: Container(
                              width: 44,
                              height: 4,
                              margin: EdgeInsets.only(
                                top: isCompact ? 8 : 12,
                                bottom: isCompact ? 6 : 8,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD0D0D0),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        )
                      else
                        SizedBox(height: isCompact ? 4 : 6),

                      // Compact bar: only visible when collapsed
                      if (isCollapsed)
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            20,
                            2,
                            20,
                            isCompact ? 6 : 8,
                          ), // ✅ add a tiny bottom padding
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      (_shipment?['delivery_address'] ??
                                              _shipment?['location'] ??
                                              'Shipment')
                                          .toString(),
                                      maxLines: 1,
                                      overflow: TextOverflow
                                          .ellipsis, // ✅ avoids overflow in narrow landscape
                                      style: TextStyle(
                                        fontSize: isCompact ? 16 : 18,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF1C1B1F),
                                      ),
                                    ),
                                    const SizedBox(height: 2), // ✅ tighter
                                    Text(
                                      _loading
                                          ? 'Loading...'
                                          : 'Shipment details',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: isCompact ? 13 : 14,
                                        color: Color(0xFF606060),
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Material(
                                color: Colors.white,
                                shape: const CircleBorder(
                                  side: BorderSide(
                                    color: Colors.black,
                                    width: 1,
                                  ),
                                ),
                                elevation: 1,
                                child: InkWell(
                                  onTap: _expandSheet,
                                  customBorder: const CircleBorder(),
                                  child: Container(
                                    padding: EdgeInsets.all(isCompact ? 5 : 6),
                                    child: Icon(
                                      Symbols.keyboard_arrow_up_rounded,
                                      size: isCompact ? 30 : 34,
                                      color: Color(0xFF1C1B1F),
                                      fill: 1,
                                      weight: 100,
                                      grade: 200,
                                      opticalSize: 24,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      if (showFullCard)
                        Expanded(
                          child: Column(
                            children: [
                              Expanded(
                                child: SingleChildScrollView(
                                  controller: scrollController,
                                  padding: EdgeInsets.fromLTRB(
                                    20,
                                    0,
                                    20,
                                    isCompact ? 10 : 8,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (_loading)
                                        const Padding(
                                          padding: EdgeInsets.symmetric(
                                            vertical: 20,
                                          ),
                                          child: Center(
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          ),
                                        ),
                                      if (_error.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 8,
                                          ),
                                          child: Text(
                                            _error,
                                            style: const TextStyle(
                                              color: Color(0xFFE3001B),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      Text(
                                        'Expected on: ${(_shipment?['expected_on'] ?? '—').toString()}',
                                        style: TextStyle(
                                          fontSize: isCompact ? 21 : 23,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF1C1B1F),
                                        ),
                                      ),

                                      SizedBox(height: isCompact ? 4 : 6),

                                      // ✅ METRICS (EXACT: 3 columns in one row)
                                      Row(
                                        children: [
                                          Expanded(
                                            flex: 2,
                                            child: _MetricItem(
                                              icon: Symbols.deployed_code,
                                              value:
                                                  (_shipment?['transaction_label'] ??
                                                          _shipment?['transaction_id'] ??
                                                          '—')
                                                      .toString(),
                                              label: 'Transaction ID',
                                              alignCenter: false,
                                            ),
                                          ),
                                          Expanded(
                                            flex: 1,
                                            child: _MetricItem(
                                              value: '—',
                                              label: 'Distance',
                                              alignCenter: false,
                                            ),
                                          ),
                                          Expanded(
                                            flex: 1,
                                            child: _MetricItem(
                                              value: '—',
                                              label: 'Travel time',
                                              alignCenter: false,
                                            ),
                                          ),
                                        ],
                                      ),

                                      SizedBox(height: isCompact ? 8 : 11),
                                      const Divider(
                                        height: 1,
                                        thickness: 1,
                                        color: Color(0xFFE8E8E8),
                                      ),
                                      SizedBox(height: isCompact ? 8 : 11),

                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Customer',
                                                  style: TextStyle(
                                                    fontSize: isCompact
                                                        ? 15
                                                        : 16,
                                                    color: Color(0xFF606060),
                                                    fontWeight: FontWeight.w400,
                                                  ),
                                                ),
                                                Text(
                                                  (_shipment?['customer_name'] ??
                                                          '—')
                                                      .toString(),
                                                  style: TextStyle(
                                                    fontSize: isCompact
                                                        ? 17
                                                        : 18,
                                                    fontWeight: FontWeight.w600,
                                                    color: Color(0xFF1C1B1F),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (_showDeliverNow) ...[
                                            SizedBox(width: isCompact ? 8 : 10),
                                            _ActionIconButton(
                                              icon: Symbols.chat_bubble,
                                              onTap: _openChat,
                                            ),
                                            SizedBox(width: isCompact ? 8 : 10),
                                            _ActionIconButton(
                                              icon: Symbols.call,
                                              onTap: _openCall,
                                            ),
                                          ],
                                        ],
                                      ),

                                      SizedBox(height: isCompact ? 8 : 12),

                                      Text(
                                        'Delivery address:',
                                        style: TextStyle(
                                          fontSize: isCompact ? 15.5 : 16.5,
                                          color: Color(0xFF606060),
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),

                                      Text(
                                        (_shipment?['delivery_address'] ??
                                                _shipment?['location'] ??
                                                '—')
                                            .toString(),
                                        style: TextStyle(
                                          fontSize: isCompact ? 17 : 18,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF1C1B1F),
                                          height: 1.35,
                                        ),
                                      ),

                                      SizedBox(height: isCompact ? 8 : 12),

                                      // Order details card
                                      Container(
                                        width: double.infinity,
                                        padding: EdgeInsets.symmetric(
                                          horizontal: detailsHorizontalPadding,
                                          vertical: detailsVerticalPadding,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF2F2F2),
                                          borderRadius: BorderRadius.circular(
                                            detailsRadius,
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            _OrderRow(
                                              label: 'Quantity:',
                                              value:
                                                  (_shipment?['quantity'] ??
                                                          '1')
                                                      .toString(),
                                            ),
                                            _OrderRow(
                                              label: 'Size:',
                                              value: (_shipment?['size'] ?? '—')
                                                  .toString(),
                                            ),
                                            _OrderRow(
                                              label: 'Order:',
                                              value:
                                                  (_shipment?['order_name'] ??
                                                          _shipment?['product_name'] ??
                                                          '—')
                                                      .toString(),
                                            ),
                                            _OrderRow(
                                              label: 'Order Type:',
                                              value:
                                                  (_shipment?['order_type'] ??
                                                          '—')
                                                      .toString(),
                                            ),
                                            _OrderRow(
                                              label: 'Total Amount:',
                                              value: _fmtMoney(
                                                _shipment?['cost_text'] ??
                                                    _shipment?['cost'],
                                              ),
                                            ),
                                            _OrderRow(
                                              label: 'Down Payment:',
                                              value: _fmtMoney(
                                                _shipment?['downpayment'],
                                              ),
                                            ),
                                            _OrderRow(
                                              label: 'Balance:',
                                              value: _fmtMoney(
                                                _shipment?['balance'],
                                              ),
                                            ),
                                            _OrderRow(
                                              label: 'Customer Number:',
                                              value:
                                                  (_shipment?['customer_phone'] ??
                                                          '—')
                                                      .toString(),
                                            ),
                                          ],
                                        ),
                                      ),

                                      SizedBox(height: isCompact ? 12 : 17),
                                      // "Deliver now" only when status is "ready" (not when preparing)
                                      _showDeliverNow
                                          ? Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.stretch,
                                              children: [
                                                if (!_canDeliverNow &&
                                                    _orderStatus == 'preparing')
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                          bottom: 8,
                                                        ),
                                                    child: Text(
                                                      'Order is being prepared. You can deliver when Ice Cream is Ready.',
                                                      style: TextStyle(
                                                        fontSize: isCompact
                                                            ? 12
                                                            : 13,
                                                        color: const Color(
                                                          0xFF606060,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                SizedBox(
                                                  width: double.infinity,
                                                  child: ElevatedButton(
                                                    onPressed:
                                                        (_loading ||
                                                            _submitting ||
                                                            !_canDeliverNow)
                                                        ? null
                                                        : () async {
                                                            final ok =
                                                                await _postShipmentAction(
                                                                  'deliver',
                                                                );
                                                            if (!mounted || !ok)
                                                              return;
                                                            Navigator.pushReplacement(
                                                              context,
                                                              MaterialPageRoute(
                                                                builder: (_) => CompleteDeliveryPage(
                                                                  shipmentId:
                                                                      _shipmentId,
                                                                  initialShipment:
                                                                      _shipment,
                                                                ),
                                                              ),
                                                            );
                                                          },
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor:
                                                          const Color(
                                                            0xFFE3001B,
                                                          ),
                                                      foregroundColor:
                                                          Colors.white,
                                                      disabledBackgroundColor:
                                                          Colors.grey.shade300,
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                            vertical: isCompact
                                                                ? 13
                                                                : 16,
                                                          ),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              999,
                                                            ),
                                                      ),
                                                      elevation: 0,
                                                    ),
                                                    child: Text(
                                                      'Deliver now',
                                                      style: TextStyle(
                                                        fontSize: isCompact
                                                            ? 15
                                                            : 16,
                                                        fontWeight:
                                                            FontWeight.w400,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            )
                                          : Row(
                                              children: [
                                                Expanded(
                                                  flex: 2,
                                                  child: ElevatedButton(
                                                    onPressed:
                                                        (_loading ||
                                                            _submitting)
                                                        ? null
                                                        : () async {
                                                            final ok =
                                                                await _postShipmentAction(
                                                                  'accept',
                                                                );
                                                            if (!mounted || !ok)
                                                              return;
                                                            setState(
                                                              () =>
                                                                  _showDeliverNow =
                                                                      true,
                                                            );
                                                            _loadShipment();
                                                          },
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor:
                                                          const Color(
                                                            0xFF007CFF,
                                                          ),
                                                      foregroundColor:
                                                          Colors.white,
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                            vertical: isCompact
                                                                ? 13
                                                                : 16,
                                                          ),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              999,
                                                            ),
                                                      ),
                                                      elevation: 0,
                                                    ),
                                                    child: Text(
                                                      'Accept Book',
                                                      style: TextStyle(
                                                        fontSize: isCompact
                                                            ? 15
                                                            : 16,
                                                        fontWeight:
                                                            FontWeight.w400,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: OutlinedButton(
                                                    onPressed:
                                                        (_loading ||
                                                            _submitting)
                                                        ? null
                                                        : () async {
                                                            final ok =
                                                                await _postShipmentAction(
                                                                  'reject',
                                                                );
                                                            if (!mounted || !ok)
                                                              return;
                                                            Navigator.pop(
                                                              context,
                                                              true,
                                                            );
                                                          },
                                                    style: OutlinedButton.styleFrom(
                                                      side: const BorderSide(
                                                        color: Color(
                                                          0xFFE3001B,
                                                        ),
                                                      ),
                                                      foregroundColor:
                                                          const Color(
                                                            0xFFE3001B,
                                                          ),
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                            vertical: isCompact
                                                                ? 13
                                                                : 16,
                                                          ),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              999,
                                                            ),
                                                      ),
                                                    ),
                                                    child: Text(
                                                      'Reject',
                                                      style: TextStyle(
                                                        fontSize: isCompact
                                                            ? 15
                                                            : 16,
                                                        fontWeight:
                                                            FontWeight.w400,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                      SizedBox(height: isCompact ? 10 : 12),
                                    ],
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
            },
          ),

          // Overlay when collapsed: capture tap so circle/bar expands sheet (sheet drag won't steal tap)
          if (_sheetController.isAttached && _sheetController.size <= 0.2)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: MediaQuery.of(context).size.height * 0.12,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _expandSheet,
                child: const SizedBox.expand(),
              ),
            ),
        ],
      ),
    );
  }
}

class _MetricItem extends StatelessWidget {
  final IconData? icon;
  final String value;
  final String label;
  final bool alignCenter;

  const _MetricItem({
    this.icon,
    required this.value,
    required this.label,
    required this.alignCenter,
  });

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.of(context).size.height < 760;
    // Left item: icon + text stack like screenshot
    if (icon != null) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: isCompact ? 32 : 36,
            height: isCompact ? 32 : 36,
            decoration: const BoxDecoration(
              color: Color(0xFFF2F2F2),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              icon,
              size: isCompact ? 16 : 18,
              color: const Color(0xFF1C1B1F),
            ),
          ),
          SizedBox(width: isCompact ? 8 : 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: isCompact ? 17 : 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1C1B1F),
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 0),
              Text(
                label,
                style: TextStyle(
                  fontSize: isCompact ? 14 : 15,
                  color: const Color(0xFF575757),
                  fontWeight: FontWeight.w400,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ],
      );
    }

    // Middle / Right items: centered stacked text
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: alignCenter
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Text(
          value,
          textAlign: alignCenter ? TextAlign.center : TextAlign.left,
          style: TextStyle(
            fontSize: isCompact ? 16 : 17,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1C1B1F),
            height: 1.1,
          ),
        ),
        const SizedBox(height: 0),
        Text(
          label,
          textAlign: alignCenter ? TextAlign.center : TextAlign.left,
          style: TextStyle(
            fontSize: isCompact ? 13 : 14,
            color: const Color(0xFF8B8B8B),
            fontWeight: FontWeight.w400,
            height: 1.1,
          ),
        ),
      ],
    );
  }
}

class _OrderRow extends StatelessWidget {
  final String label;
  final String value;

  const _OrderRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.of(context).size.height < 760;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: isCompact ? 4 : 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// LEFT — LABEL
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: TextStyle(
                fontSize: isCompact ? 13.5 : 14.5,
                color: const Color(0xFF7A7A7A),
                fontWeight: FontWeight.w400,
              ),
            ),
          ),

          /// RIGHT — VALUE (RIGHT ALIGNED)
          Expanded(
            flex: 5,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                textAlign: TextAlign.left,
                style: TextStyle(
                  fontSize: isCompact ? 13.5 : 14.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1C1B1F),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _ActionIconButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.of(context).size.height < 760;

    return Material(
      color: Colors.white,
      shape: const CircleBorder(
        side: BorderSide(color: Colors.black, width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: isCompact ? 44 : 48,
          height: isCompact ? 44 : 48,
          child: Icon(
            icon,
            size: isCompact ? 20 : 22,
            color: const Color(0xFF1C1B1F),
            fill: 1,
            weight: 300,
            grade: 200,
            opticalSize: 24,
          ),
        ),
      ),
    );
  }
}
