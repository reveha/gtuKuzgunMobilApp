import 'package:flutter/material.dart';

class AuthPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Giriş/Kayıt'),
        backgroundColor: Colors.indigo, // Lacivert arka plan rengi
      ),
      backgroundColor: Colors.white, // Beyaz ana arka plan rengi
      body: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 50,
            child: Image.asset(
              'assets/images/logo.png', // Drone resmi buraya eklenecek
              height: 150,
              width: 150,
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  child: Text('Kayıt Ol'),
                  onPressed: () {
                    Navigator.pushNamed(context, '/register');
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.indigo,
                  ),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  child: Text('Giriş Yap'),
                  onPressed: () {
                    Navigator.pushNamed(context, '/login');
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.indigo,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
