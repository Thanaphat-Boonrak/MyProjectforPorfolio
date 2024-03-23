import 'dart:io';

import 'package:chat_app/widget/user_image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

final _firebase = FirebaseAuth.instance;

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() {
    return _AuthScreenState();
  }
}

class _AuthScreenState extends State<AuthScreen> {
  final _formkey = GlobalKey<FormState>();
  var _email = '';
  var _password = '';
  var _isPass = true;
  var _isLogin = true;
  File? _selectedImage;
  var _isUploading = false;
  var _username = '';

  void submit() async {
    final isvalid = _formkey.currentState!.validate();
    if (!isvalid || !_isLogin && _selectedImage == null) {
      return;
    }

    _formkey.currentState!.save();
    if (_isLogin) {
      final userCredential = await _firebase.signInWithEmailAndPassword(
          email: _email, password: _password);
    } else {
      try {
        setState(() {
          _isUploading = true;
        });
        final userCredential = await _firebase.createUserWithEmailAndPassword(
            email: _email, password: _password);
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('User-Image')
            .child('${userCredential.user!.uid}.jpg');
        await storageRef.putFile(_selectedImage!);
        final imageUrl = await storageRef.getDownloadURL();

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
          'username': _username,
          'email': _email,
          'image_url': imageUrl
        });
      } on FirebaseAuthException catch (error) {
        if (error.code == 'email-already-in-use') {
          //..
        }
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.message ?? 'Authentication Failed'),
          ),
        );
      }
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
          child: SingleChildScrollView(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            margin: const EdgeInsets.only(
              top: 30,
              bottom: 20,
              left: 20,
              right: 20,
            ),
            width: 200,
            child: Image.asset('assets/images/chat.png'),
          ),
          Card(
            margin: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formkey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!_isLogin)
                        UserImagePicker(
                          onPickImage: (pickedImage) {
                            _selectedImage = pickedImage;
                          },
                        ),
                      TextFormField(
                        decoration: const InputDecoration(
                            labelText: 'Email Address',
                            icon: Icon(Icons.email)),
                        keyboardType: TextInputType.emailAddress,
                        autocorrect: false,
                        textCapitalization: TextCapitalization.none,
                        validator: (value) {
                          if (value == null ||
                              value.trim().isEmpty ||
                              !value.contains('@')) {
                            return 'Please enter a valid email address.';
                          }
                          return null;
                        },
                        onSaved: (value) {
                          _email = value!;
                        },
                      ),
                      if (!_isLogin)
                        TextFormField(
                          decoration: const InputDecoration(
                            icon: Icon(Icons.assignment),
                            label: Text('Username'),
                          ),
                          enableSuggestions: false,
                          validator: (value) {
                            if (value == null ||
                                value.isEmpty ||
                                value.trim().length < 4) {
                              return 'Please Enter at least 4 characters';
                            }
                            return null;
                          },
                          onSaved: (value) {
                            _username = value!;
                          },
                        ),
                      TextFormField(
                        textAlign: TextAlign.left,
                        decoration: const InputDecoration(
                          icon: Icon(Icons.password_sharp),
                          labelText: 'Password',
                        ),
                        obscureText: _isPass,
                        validator: (value) {
                          if (value == null || value.trim().length < 6) {
                            return 'Password must be at least 6 character long';
                          }
                          return null;
                        },
                        onSaved: (value) {
                          _password = value!;
                        },
                      ),
                      const SizedBox(
                        height: 16,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _isPass = _isPass ? false : true;
                              });
                            },
                            icon: _isPass
                                ? const Icon(Icons.visibility_off)
                                : const Icon(Icons.visibility),
                          ),
                          if (_isUploading) CircularProgressIndicator(),
                          if (!_isUploading)
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context)
                                      .colorScheme
                                      .primaryContainer),
                              onPressed: submit,
                              child: _isLogin
                                  ? const Text("Login")
                                  : const Text("Sign Up"),
                            ),
                          const SizedBox(
                            width: 10,
                          ),
                          if (!_isUploading)
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _isLogin = _isLogin ? false : true;
                                });
                              },
                              child: _isLogin
                                  ? const Text("Create an account")
                                  : const Text("I already have an ccount"),
                            ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ),
          )
        ]),
      )),
    );
  }
}
