import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:Kuzgun/qr_scan_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_svg/flutter_svg.dart';

class TrackingPage extends StatefulWidget {
  final DocumentSnapshot drone;

  TrackingPage({required this.drone});

  @override
  _TrackingPageState createState() => _TrackingPageState();
}

class _TrackingPageState extends State<TrackingPage> {
  late GoogleMapController mapController;
  late StreamSubscription<QuerySnapshot> _subscription;
  Set<Marker> _markers = Set<Marker>();
  Set<Polyline> _polylines = Set<Polyline>();
  LatLng _phoneLocation = LatLng(0, 0); // Initialize with a default value
  late Timer _timer;
  DocumentSnapshot? _orderDocument; // Store the order document
  String _arrivalTime = 'Calculating...'; // To hold the estimated arrival time

  @override
  void initState() {
    super.initState();
    _getCurrentLocation(); // Get initial location
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      _getCurrentLocation();
    });
    _subscribeToOrderUpdates(); // Subscribe to order updates
  }

  @override
  void dispose() {
    _subscription.cancel();
    _timer.cancel();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    print('Current location: ${position.latitude}, ${position.longitude}');
    setState(() {
      _phoneLocation = LatLng(position.latitude, position.longitude);
      _markers.add(Marker(
        markerId: MarkerId('phone_location'),
        position: _phoneLocation,
        infoWindow: InfoWindow(title: 'Phone Location'),
      ));
    });
    _updatePolylines(); // Update polylines with the new phone location
    _updateArrivalTime(); // Update estimated arrival time
  }

  Future<BitmapDescriptor> _loadSvgMarker(String svgAsset) async {
    String svgString = await DefaultAssetBundle.of(context).loadString(svgAsset);
    DrawableRoot svgDrawableRoot = await svg.fromSvgString(svgString, svgString);

    ui.Picture picture = svgDrawableRoot.toPicture();
    ui.Image image = await picture.toImage(100, 100);
    ByteData? bytes = await image.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
  }

  void _subscribeToOrderUpdates() {
    _subscription = FirebaseFirestore.instance
        .collection('orders')
        .where('droneId', isEqualTo: widget.drone.id)
        .snapshots()
        .listen((querySnapshot) async {
      if (querySnapshot.docs.isNotEmpty) {
        _orderDocument = querySnapshot.docs.first;
        GeoPoint geoPoint = _orderDocument!['location'];
        BitmapDescriptor droneIcon = await _loadSvgMarker('assets/images/dronee.svg');

        setState(() {
          _markers.add(Marker(
            markerId: MarkerId(widget.drone.id),
            position: LatLng(geoPoint.latitude, geoPoint.longitude),
            infoWindow: InfoWindow(title: 'Drone'),
            icon: droneIcon,
          ));
        });
        _updatePolylines(); // Update polylines with the new drone location
        _centerMapOnDroneLocation(); // Center map on drone location
        _updateArrivalTime(); // Update estimated arrival time
      }
    });
  }

  void _updatePolylines() {
    // Clear existing polylines
    _polylines.clear();

    // Get the latest drone and phone locations
    if (_markers.isNotEmpty) {
      Marker? droneMarker = _markers.firstWhere(
            (marker) => marker.markerId == MarkerId(widget.drone.id),
        orElse: () => Marker(markerId: MarkerId('none')),
      );
      if (droneMarker.markerId != MarkerId('none') && _phoneLocation != LatLng(0, 0)) {
        _polylines.add(Polyline(
          polylineId: PolylineId('drone_path'),
          points: [
            droneMarker.position,
            _phoneLocation,
          ],
          color: const Color(0xFF7B61FF),
          width: 5,
        ));
      }
    }
  }

  void _centerMapOnDroneLocation() {
    if (_markers.isNotEmpty) {
      Marker? droneMarker = _markers.firstWhere(
            (marker) => marker.markerId == MarkerId(widget.drone.id),
        orElse: () => Marker(markerId: MarkerId('none')),
      );
      if (droneMarker.markerId != MarkerId('none')) {
        mapController.animateCamera(CameraUpdate.newLatLngZoom(
          droneMarker.position,
          12.0, // Adjust zoom level here
        ));
      }
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    setState(() {
      mapController = controller;
      _centerMapOnDroneLocation(); // Center map when created
    });
  }

  String _calculateArrivalTime(double distance) {
    const double speedKmH = 20.0; // Drone speed in km/h
    double timeHours = distance / speedKmH; // Time in hours
    int minutes = (timeHours * 60).round(); // Convert hours to minutes
    return '$minutes dakika';
  }

  void _updateArrivalTime() {
    if (_markers.isNotEmpty) {
      Marker? droneMarker = _markers.firstWhere(
            (marker) => marker.markerId == MarkerId(widget.drone.id),
        orElse: () => Marker(markerId: MarkerId('none')),
      );
      if (droneMarker.markerId != MarkerId('none') && _phoneLocation != LatLng(0, 0)) {
        double distance = _calculateDistance(
          _phoneLocation.latitude,
          _phoneLocation.longitude,
          droneMarker.position.latitude,
          droneMarker.position.longitude,
        );
        setState(() {
          _arrivalTime = _calculateArrivalTime(distance);
        });
      }
    }
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371;
    double dLat = _toRadians(lat2 - lat1);
    double dLon = _toRadians(lon2 - lon1);
    double latRad1 = _toRadians(lat1);
    double latRad2 = _toRadians(lat2);

    double a = sin(dLat / 2) * sin(dLat / 2) +
        sin(dLon / 2) * sin(dLon / 2) * cos(latRad1) * cos(latRad2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    double distance = R * c;

    return distance;
  }

  double _toRadians(double deg) {
    return deg * pi / 180;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Drone Takip Sayfasi'),
        backgroundColor: Colors.indigo,
      ),
      body: Column(
        children: [
          // Map section
          Container(
            height: 350, // Adjust the height as needed
            child: GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: _markers.isNotEmpty
                    ? _markers.first.position
                    : LatLng(0, 0),
                zoom: 12.0, // Adjust zoom level here
              ),
              markers: _markers,
              polylines: _polylines,
            ),
          ),
          // Drone information section
          Expanded(
            child: _orderDocument != null
                ? Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Drone ID: ${_orderDocument!['droneId']}'),
                  Text('Drone Konumu: ${_orderDocument!['location'].longitude} && ${_orderDocument!['location'].latitude}'),
                  Text('Drone İsmi: ${_orderDocument!['droneName']}'),
                  Text('Drone Durumu: ${_orderDocument!['status']}'),
                  Text('Araç Plakası: ${_orderDocument!['carPlate']}'),
                  SizedBox(height: 16.0),
                  Text('Tahmini Varış Süresi: $_arrivalTime'),
                  // Add more drone information as needed
                ],
              ),
            )
                : Center(child: CircularProgressIndicator()),
          ),
          // Video feed placeholder
          Container(
            height: 100,
            color: Colors.grey[200],
            child: Center(
              child: Text(
                'Bu kısma drone\'u canlı izleme ekranı eklenecektir.',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          // Deliver button
          Padding(
            padding: const EdgeInsets.all(30.0),
            child: _orderDocument != null && _orderDocument!['status'] == 'Arrived'
                ? ElevatedButton(
              onPressed: () {
                // Deliver button pressed, navigate to QRScanPage
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => QRScanPage(),
                  ),
                );
              },
              child: Text('Teslim Al'),
            )
                : null,
          ),
        ],
      ),
    );
  }
}
