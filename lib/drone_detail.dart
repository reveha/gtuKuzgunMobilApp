import 'package:Kuzgun/tracking_page.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DroneDetailPage extends StatelessWidget {
  final DocumentSnapshot drone;

  DroneDetailPage({required this.drone});

  @override
  Widget build(BuildContext context) {
    GeoPoint geoPoint = drone['location'];

    return Scaffold(
      appBar: AppBar(
        title: Text('Drone Details'),
        backgroundColor: Colors.indigo,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Drone ID: ${drone.id}', style: TextStyle(fontSize: 24.0)),
            SizedBox(height: 16.0),
            Text('Latitude: ${geoPoint.latitude}', style: TextStyle(fontSize: 18.0)),
            Text('Longitude: ${geoPoint.longitude}', style: TextStyle(fontSize: 18.0)),
            SizedBox(height: 24.0),
            Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: ElevatedButton(
                  onPressed: () {
                    // Handle order button click
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('Order Confirmation'),
                        content: Text('You are about to order drone ID: ${drone.id}.'),
                        actions: [
                          TextButton(
                            onPressed: () {
                              // Process order logic here
                              Navigator.of(context).pop(); // Close dialog
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TrackingPage(drone: drone),
                                ),
                              );
                            },
                            child: Text('Confirm'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop(); // Close dialog
                            },
                            child: Text('Cancel'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: Text('Order Drone'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
