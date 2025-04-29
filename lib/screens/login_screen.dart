import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:garifordriver/global/global.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  void _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final authResult = await firebaseauth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        currentuser = authResult.user;

        if (currentuser != null) {
          final userRef = FirebaseDatabase.instance.ref().child("Drivers");
          final snapshot = await userRef.child(currentuser!.uid).get();

          if (snapshot.exists) {
            var prefs = await SharedPreferences.getInstance();
            prefs.setBool("islogin", true);

            Fluttertoast.showToast(
              msg: "Login Successful",
              backgroundColor: Colors.green,
              textColor: Colors.white,
              fontSize: 16.0,
            );

            Navigator.pushReplacementNamed(context, '/homescreen');
          } else {
            firebaseauth.signOut();
            Fluttertoast.showToast(
              msg: "No Driver data found for this user",
              backgroundColor: Colors.red,
              textColor: Colors.white,
              fontSize: 16.0,
            );
          }
        }
      } catch (e) {
        Fluttertoast.showToast(
          msg: e.toString(),
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: width * 0.04,
          vertical: height * 0.02,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              SizedBox(height: height * 0.08),
              Center(
                child: Image.asset(
                  'assets/images/driver_logo.png',
                  height: height * 0.2,
                  width: width * 0.6,
                ),
              ),
              SizedBox(height: height * 0.015),
              Text(
                'Login to your account',
                style: TextStyle(
                  fontSize: height * 0.03,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: height * 0.03),

              // Email
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                validator: (value) {
                  if (value!.isEmpty) return 'Please enter your email';
                  if (!RegExp(r'\S+@\S+\.\S+').hasMatch(value))
                    return 'Enter a valid email';
                  return null;
                },
              ),
              SizedBox(height: height * 0.015),

              // Password
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                ),
                validator:
                    (value) =>
                        value!.isEmpty ? 'Please enter your password' : null,
              ),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/forgotpassword');
                  },
                  child: Text(
                    'Forgot Password?',
                    style: TextStyle(
                      color: const Color.fromARGB(255, 192, 57, 245),
                      fontSize: height * 0.018,
                    ),
                  ),
                ),
              ),

              // Login Button
              SizedBox(
                width: double.infinity,
                height: height * 0.065,
                child:
                    _isLoading
                        ? Center(
                          child: CircularProgressIndicator(
                            color: Colors.yellow,
                          ),
                        )
                        : ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.yellow,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: _login,
                          child: Text(
                            'Login',
                            style: TextStyle(
                              fontSize: height * 0.022,
                              color: Colors.black,
                            ),
                          ),
                        ),
              ),
              SizedBox(height: height * 0.02),

              Text(
                "Don't have an account?",
                style: TextStyle(
                  fontSize: height * 0.018,
                  color: Colors.black54,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/registerscreen');
                },
                child: Text('Register'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
