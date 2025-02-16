import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

class HomeViewBody extends StatefulWidget {
  const HomeViewBody({super.key});

  @override
  State<HomeViewBody> createState() => _HomeViewBodyState();
}

class _HomeViewBodyState extends State<HomeViewBody> {
  final Location _locationManager = Location();
  GoogleMapController? _controller;
  StreamSubscription<LocationData>? _trackingService;
  bool _isTracking = false;
  bool _isMovingToHome = false;

  static const String _homeId = 'home_location';
  static const String _userLocationId = 'user_location';
  static const LatLng _homeLocation = LatLng(30.6445333, 31.7894096);

  LatLng? _userPosition;
  final Set<Marker> _markers = {
    const Marker(markerId: MarkerId(_homeId), position: _homeLocation),
  };

  @override
  void initState() {
    super.initState();
    _initializeLocationTracking();
  }

  Future<void> _initializeLocationTracking() async {
    if (await _requestPermissionsAndServices()) {
      _getCurrentUserLocation();
    }
  }

  Future<bool> _requestPermissionsAndServices() async {
    return await _requestPermission() && await _requestLocationService();
  }

  Future<bool> _requestPermission() async {
    var permissionStatus = await _locationManager.requestPermission();
    return permissionStatus == PermissionStatus.granted;
  }

  Future<bool> _requestLocationService() async {
    return await _locationManager.requestService();
  }

  void _toggleTracking() {
    setState(() => _isTracking = !_isTracking);
    _isTracking ? _startTracking() : _stopTracking();
  }

  void _startTracking() {
    _trackingService?.cancel();
    _trackingService = _locationManager.onLocationChanged.listen((locationData) {
      if (locationData.latitude != null && locationData.longitude != null) {
        setState(() {
          _userPosition = LatLng(locationData.latitude!, locationData.longitude!);
          _updateUserMarker(_userPosition!);
        });
      }
    });
  }

  void _moveUserTowardsHome() {
    if (_userPosition == null || _isMovingToHome) return;
    _isMovingToHome = true;
    
    const double step = 0.0005;
    Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (_userPosition == null) {
        timer.cancel();
        _isMovingToHome = false;
        return;
      }

      double latDiff = _homeLocation.latitude - _userPosition!.latitude;
      double lngDiff = _homeLocation.longitude - _userPosition!.longitude;

      if (latDiff.abs() < step && lngDiff.abs() < step) {
        _updateUserMarker(_homeLocation);
        timer.cancel();
        _isMovingToHome = false;
        return;
      }

      double latStep = latDiff.abs() > step ? (latDiff > 0 ? step : -step) : latDiff;
      double lngStep = lngDiff.abs() > step ? (lngDiff > 0 ? step : -step) : lngDiff;
      
      setState(() {
        _userPosition = LatLng(_userPosition!.latitude + latStep, _userPosition!.longitude + lngStep);
        _updateUserMarker(_userPosition!);
      });
      _controller?.animateCamera(CameraUpdate.newLatLng(_userPosition!));
    });
  }

  Future<void> _getCurrentUserLocation() async {
    LocationData locationData = await _locationManager.getLocation();
    if (locationData.latitude != null && locationData.longitude != null) {
      setState(() {
        _userPosition = LatLng(locationData.latitude!, locationData.longitude!);
        _updateUserMarker(_userPosition!);
      });
    }
  }

  void _updateUserMarker(LatLng position) {
    setState(() {
      _markers.removeWhere((marker) => marker.markerId.value == _userLocationId);
      _markers.add(Marker(markerId: const MarkerId(_userLocationId), position: position));
    });
  }

  void _stopTracking() {
    _trackingService?.cancel();
    _trackingService = null;
  }

  @override
  void dispose() {
    _stopTracking();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: _toggleTracking,
          child: Text(_isTracking ? 'Stop Tracking' : 'Track Location'),
        ),
        ElevatedButton(
          onPressed: _moveUserTowardsHome,
          child: const Text('Move to Home'),
        ),
        Expanded(
          child: GoogleMap(
            markers: _markers,
            mapType: MapType.normal,
            initialCameraPosition: const CameraPosition(target: _homeLocation, zoom: 16),
            onMapCreated: (GoogleMapController controller) {
              _controller = controller;
              _initializeLocationTracking();
            },
          ),
        ),
      ],
    );
  }
}
