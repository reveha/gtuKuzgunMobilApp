import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  final List<TextEditingController> _carPlateControllers = [];

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _carPlateControllers.forEach((controller) => controller.dispose());
    super.dispose();
  }

  void _addCarPlateField() {
    setState(() {
      _carPlateControllers.add(TextEditingController());
    });
  }

  void _removeCarPlateField(int index) {
    setState(() {
      _carPlateControllers[index].dispose();
      _carPlateControllers.removeAt(index);
    });
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      try {
        UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );

        // Collect car plate values
        List<String> carPlates = _carPlateControllers.map((controller) => controller.text).toList();

        // Add user info to Firestore
        await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
          'name': _nameController.text,
          'email': _emailController.text,
          'cars': carPlates, // Store the list of car plates
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Başarıyla kayıt oldunuz! Yönlendiriliyorsunuz...'),
            duration: Duration(seconds: 2),
          ),
        );

        // Wait for the SnackBar to disappear before navigating
        await Future.delayed(Duration(seconds: 2));

        // Navigate to login page
        Navigator.pushReplacementNamed(context, '/login');
      } catch (e) {
        print('Error: $e');
        // TODO: Handle registration errors, show snackbar or alert dialog
      }
    }
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Parola gerekli';
    }
    if (value.length < 8) {
      return 'Parola en az 8 karakter olmalı';
    }
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Parola en az bir büyük harf içermeli';
    }
    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Parola en az bir küçük harf içermeli';
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Parola en az bir rakam içermeli';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kayıt Ol'),
        backgroundColor: Colors.indigo, // Lacivert arka plan rengi
      ),
      backgroundColor: Colors.white, // Beyaz ana arka plan rengi
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Image.asset(
                          'assets/images/logo.png',
                          height: 100,
                          width: 100,
                        ),
                      ),
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Ad Soyad',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person, color: Colors.indigo),
                        ),
                        validator: (value) {
                          if (value!.isEmpty) {
                            return 'Ad soyad gerekli';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email, color: Colors.indigo),
                        ),
                        validator: (value) {
                          if (value!.isEmpty) {
                            return 'Email gerekli';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: 'Parola',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.lock, color: Colors.indigo),
                        ),
                        obscureText: true,
                        validator: _validatePassword,
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _confirmPasswordController,
                        decoration: InputDecoration(
                          labelText: 'Parola Tekrar',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.lock, color: Colors.indigo),
                        ),
                        obscureText: true,
                        validator: (value) {
                          if (value!.isEmpty) {
                            return 'Parola doğrulama gerekli';
                          }
                          if (value != _passwordController.text) {
                            return 'Parolalar eşleşmiyor';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      ..._carPlateControllers.asMap().entries.map((entry) {
                        int index = entry.key;
                        TextEditingController controller = entry.value;
                        return Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: controller,
                                decoration: InputDecoration(
                                  labelText: 'Araç Plakası ${index + 1}',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.car_repair, color: Colors.indigo),
                                ),
                                validator: (value) {
                                  if (value!.isEmpty) {
                                    return 'Araç plakası gerekli';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.remove_circle, color: Colors.red),
                              onPressed: () => _removeCarPlateField(index),
                            ),
                          ],
                        );
                      }).toList(),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _addCarPlateField,
                        child: Text('Yeni Araç Ekle'),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white, backgroundColor: Colors.indigo,
                        ),
                      ),
                      SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _register,
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white, backgroundColor: Colors.indigo,
                        ),
                        child: Text('Kayıt Ol'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
