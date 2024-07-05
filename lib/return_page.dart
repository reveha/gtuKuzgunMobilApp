import 'package:flutter/material.dart';

class ReturnPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Drone Üsse Dönüş'),
      ),
      body: Center(
        child: Text('Drone üsse dönüyor...'),
      ),
    );
  }
}
