import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            children: [
              const SizedBox(height: 80),
             const SizedBox(
                      width: 250, 
                      height: 250, 
                      child: Image(image: AssetImage('assets/logo.png')),
                    ),
              // SizedBox(height: 20),
                const Align(
                alignment: Alignment.center,
                child: Text(
                  "Welcome Back!",
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold , color: Color(0xFF7826B5) ,),
                ),
                ),
              const SizedBox(height: 15),
             TextField(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0), // Set the desired border radius
                        ),
                        labelText: 'Username',
                        hintText: 'Enter your username', // Add hint text
                        prefixIcon: Icon(Icons.person), // Add icon
                      ),
                    ),
                    const SizedBox(height: 20),
              TextField(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0), // Set the desired border radius
                        ),
                        labelText: 'Password',
                        hintText: 'Enter your password', // Add hint text
                        prefixIcon: Icon(Icons.lock), // Add icon
                      ),
                    ),
              const SizedBox(height: 20),
               const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Forgot Password?",
                  style:  TextStyle(fontSize: 14, fontWeight: FontWeight.bold , color: Color(0xFF7826B5) ),
                ),
              ),
               const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7826B5),
                  
                  padding: const EdgeInsets.symmetric(horizontal: 150, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12), 
                  ),
                ),
                onPressed: () {},
                child: const Text('Login' , style: TextStyle(color: Colors.white),),
              ),

              const SizedBox(height: 20),
              const Align(
                alignment: Alignment.center,
                child: Text(
                  "Don't have an account?",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold , color: Color(0xFF7826B5) ),
                ),
              ),
             InkWell(
                  onTap: () {
                    Navigator.pushNamed(context, '/signup');
                  },
                  child: const Text(
                    'Sign Up',
                    style: TextStyle(
                      color: Color(0xFF7826B5),
                      fontSize: 15,
                      decoration: TextDecoration.underline,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
           
            ],
          ),
        ),
      ),

    );
  }
}