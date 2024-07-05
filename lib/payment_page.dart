import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentPage extends StatefulWidget {
  @override
  _PaymentPageState createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _cvvController = TextEditingController();

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryDateController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  Future<void> _makePayment() async {
    if (_formKey.currentState!.validate()) {
      // Process payment here and add transaction details to Firestore
      await FirebaseFirestore.instance.collection('payments').add({
        'cardNumber': _cardNumberController.text,
        'expiryDate': _expiryDateController.text,
        'cvv': _cvvController.text,
        'timestamp': Timestamp.now(),
      });

      // Navigate to tracking page
      Navigator.pushReplacementNamed(context, '/tracking');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ödeme'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _cardNumberController,
                decoration: InputDecoration(labelText: 'Kart Numarası'),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Kart numarası gerekli';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _expiryDateController,
                decoration: InputDecoration(labelText: 'Son Kullanma Tarihi'),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Son kullanma tarihi gerekli';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _cvvController,
                decoration: InputDecoration(labelText: 'CVV'),
                obscureText: true,
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'CVV gerekli';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _makePayment,
                child: Text('Ödeme Yap'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
