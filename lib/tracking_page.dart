import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:Kuzgun/qr_scan_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'QRScanPage.dart'; // QRScanPage'in doğru yolunu buraya ekleyin

class TrackingPage extends StatefulWidget {
  final DocumentSnapshot drone;

  TrackingPage({required this.drone});

  @override
  _TrackingPageState createState() => _TrackingPageState();
}

class _TrackingPageState extends State<TrackingPage> {
  late GoogleMapController mapController;
  late StreamSubscription<DocumentSnapshot> _subscription;
  Set<Marker> _markers = Set<Marker>();
  Set<Polyline> _polylines = Set<Polyline>();
  LatLng _phoneLocation = LatLng(0, 0); // Initialize with a default value
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation(); // Get initial location
    _timer = Timer.periodic(Duration(seconds: 5), (timer) {
      _getCurrentLocation();
    });
    _subscribeToLocationUpdates(); // Call _subscribeToLocationUpdates here
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
  }

  Future<BitmapDescriptor> _loadSvgMarker(String svgAsset) async {
    String svgString = await DefaultAssetBundle.of(context).loadString(svgAsset);
    DrawableRoot svgDrawableRoot = await svg.fromSvgString(svgString, svgString);

    ui.Picture picture = svgDrawableRoot.toPicture();
    ui.Image image = await picture.toImage(100, 100);
    ByteData? bytes = await image.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
  }

  void _subscribeToLocationUpdates() {
    _subscription = FirebaseFirestore.instance
        .collection('drones')
        .doc(widget.drone.id)
        .snapshots()
        .listen((snapshot) async {
      GeoPoint geoPoint = snapshot['location'];
      BitmapDescriptor droneIcon = await _loadSvgMarker('assets/images/drone.svg');

      setState(() {
        _markers.add(Marker(
          markerId: MarkerId(widget.drone.id),
          position: LatLng(geoPoint.latitude, geoPoint.longitude),
          infoWindow: InfoWindow(title: 'Drone'),
          icon: droneIcon,
        ));
      });
      _updatePolylines(); // Update polylines with the new drone location
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

  void _onMapCreated(GoogleMapController controller) {
    setState(() {
      mapController = controller;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Real-Time Tracking'),
        backgroundColor: Colors.indigo,
      ),
      body: Column(
        children: [
          // Map section
          Container(
            height: 600, // Adjust the height as needed
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('drones')
                  .doc(widget.drone.id)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  DocumentSnapshot droneData = snapshot.data!;
                  GeoPoint geoPoint = droneData['location'];

                  return GoogleMap(
                    onMapCreated: _onMapCreated,
                    initialCameraPosition: CameraPosition(
                      target: LatLng(geoPoint.latitude, geoPoint.longitude),
                      zoom: 14.0,
                    ),
                    markers: _markers,
                    polylines: _polylines,
                  );
                } else {
                  return Center(child: CircularProgressIndicator());
                }
              },
            ),
          ),
          // Drone information section
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('drones')
                  .doc(widget.drone.id)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  DocumentSnapshot droneData = snapshot.data!;
                  GeoPoint geoPoint = droneData['location'];
                  bool isArrived = droneData['status'] == 'Arrived';

                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text('Drone ID: ${droneData.id}'),
                        Text('Drone Konumu: ${geoPoint.longitude} && ${geoPoint.latitude}'),
                        Text('Drone İsmi: ${droneData['name']}'),
                        Text('Drone Durumu: ${droneData['status']}'),
                        // Add more drone information as needed
                      ],
                    ),
                  );
                } else {
                  return Center(child: CircularProgressIndicator());
                }
              },
            ),
          ),
          // Deliver button
          Padding(
            padding: const EdgeInsets.all(30.0),
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('drones')
                  .doc(widget.drone.id)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  DocumentSnapshot droneData = snapshot.data!;
                  bool isArrived = droneData['status'] == 'Arrived';

                  return ElevatedButton(
                    onPressed: isArrived ? () {
                      // Deliver button pressed, navigate to QRScanPage
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => QRScanPage(),
                        ),
                      );
                    } : null,
                    child: Text('Teslim Al'),
                  );
                } else {
                  return Center(child: CircularProgressIndicator());
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
