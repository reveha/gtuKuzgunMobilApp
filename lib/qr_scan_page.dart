import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

import 'location_page.dart';

class QRScanPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _QRScanPageState();
}

class _QRScanPageState extends State<QRScanPage> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  String? qrText;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('QR Kod Tarayıcı'),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            flex: 5,
            child: QRView(
              key: qrKey,
              onQRViewCreated: _onQRViewCreated,
              overlay: QrScannerOverlayShape(
                borderColor: Colors.red,
                borderRadius: 10,
                borderLength: 30,
                borderWidth: 10,
                cutOutSize: MediaQuery.of(context).size.width * 0.8,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: Text(
                qrText != null ? 'Scan result: $qrText' : 'Scan a code',
                style: TextStyle(fontSize: 18),
              ),
            ),
          )
        ],
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) async {
      setState(() {
        qrText = scanData.code;
      });

      if (qrText != null) {
        await _processQRCode(qrText!);
      }
    });
  }

  Future<void> _processQRCode(String qrCode) async {
    // Reference to the Firestore instance
    final firestore = FirebaseFirestore.instance;

    try {
      // Fetch the corresponding order document where droneId matches the QR code
      QuerySnapshot orderSnapshot = await firestore
          .collection('orders')
          .where('droneId', isEqualTo: qrCode)
          .limit(1)
          .get();

      if (orderSnapshot.docs.isNotEmpty) {
        DocumentSnapshot orderDoc = orderSnapshot.docs.first;

        // Update the order status to 'Done'
        await firestore.collection('orders').doc(orderDoc.id).update({
          'status': 'Done',
        });

        // Update the corresponding drone's status to 'goingBase'
        await firestore.collection('drones').doc(qrCode).update({
          'status': 'goingBase',
        });

        // Show confirmation message
        _showConfirmationDialog(
          'Success',
          'Order status updated to Done, and drone status updated to goingBase.',
              () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => LocationPage(), // Replace with your actual LocationPage
              ),
            );
          },
        );
      } else {
        _showConfirmationDialog(
          'Error',
          'No order found for the given QR code.',
              () {}, // No navigation needed for error case
        );
      }
    } catch (e) {
      _showConfirmationDialog(
        'Error',
        'An error occurred while processing the QR code.',
            () {}, // No navigation needed for error case
      );
    }
  }

  void _showConfirmationDialog(String title, String message, VoidCallback onOkPressed) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onOkPressed(); // Call the callback function
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}
