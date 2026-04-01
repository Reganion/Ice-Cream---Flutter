import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class MapPickerPage extends StatefulWidget {
  const MapPickerPage({super.key, this.initialLat, this.initialLng});

  final double? initialLat;
  final double? initialLng;

  @override
  State<MapPickerPage> createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<MapPickerPage> {
  final MapController _mapController = MapController();
  static const LatLng _defaultLocation = LatLng(10.3400, 123.9494);
  late LatLng selectedLocation =
      widget.initialLat != null && widget.initialLng != null
      ? LatLng(widget.initialLat!, widget.initialLng!)
      : _defaultLocation;
  double _zoom = 15;
  bool _loadingCurrent = false;

  void _showLocationMessage(
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: actionLabel != null && onAction != null
            ? SnackBarAction(label: actionLabel, onPressed: onAction)
            : null,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialLat == null || widget.initialLng == null) {
      _goToCurrentLocation();
    }
  }

  Future<void> _goToCurrentLocation() async {
    if (_loadingCurrent) return;
    setState(() => _loadingCurrent = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showLocationMessage(
          'Please enable location service (GPS).',
          actionLabel: 'Settings',
          onAction: Geolocator.openLocationSettings,
        );
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _showLocationMessage(
          'Location permission is required.',
          actionLabel: permission == LocationPermission.deniedForever
              ? 'App Settings'
              : null,
          onAction: permission == LocationPermission.deniedForever
              ? Geolocator.openAppSettings
              : null,
        );
        return;
      }

      Position? pos;
      try {
        pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.best,
            timeLimit: Duration(seconds: 12),
          ),
        );
      } catch (_) {
        pos = await Geolocator.getLastKnownPosition();
      }
      if (pos == null) {
        _showLocationMessage(
          'Could not determine your location yet. Move to open sky and try again.',
        );
        return;
      }
      if (!mounted) return;
      final current = LatLng(pos.latitude, pos.longitude);
      setState(() => selectedLocation = current);
      _mapController.move(current, 16);
    } on LocationServiceDisabledException {
      _showLocationMessage(
        'Location service is disabled.',
        actionLabel: 'Settings',
        onAction: Geolocator.openLocationSettings,
      );
    } catch (e) {
      _showLocationMessage('Could not get current location: $e');
    } finally {
      if (mounted) setState(() => _loadingCurrent = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pick Location"),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),

      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: selectedLocation,
              initialZoom: _zoom,
              minZoom: 4,
              maxZoom: 19,
              onTap: (_, point) {
                setState(() => selectedLocation = point);
              },
              onPositionChanged: (position, _) {
                _zoom = position.zoom;
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.hricecream.app',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: selectedLocation,
                    width: 44,
                    height: 44,
                    child: const Icon(
                      Icons.location_on,
                      size: 42,
                      color: Color(0xFFE3001B),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            top: 12,
            right: 12,
            child: Material(
              color: Colors.white,
              shape: const CircleBorder(),
              elevation: 2,
              child: IconButton(
                onPressed: _goToCurrentLocation,
                icon: _loadingCurrent
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location, color: Color(0xFF1C1B1F)),
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE3001B),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.pop(context, {
                  'lat': selectedLocation.latitude,
                  'lng': selectedLocation.longitude,
                });
              },
              child: const Text(
                "Confirm Location",
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
