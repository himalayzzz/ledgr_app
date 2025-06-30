import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
class LoginScreen extends StatelessWidget {
  LoginScreen({super.key});

  //text editing controller for email and password
   final TextEditingController emailController = TextEditingController();
   final TextEditingController passwordController = TextEditingController();


  // //login logic
  void login(BuildContext context) async{
    final email = emailController.text;
    final password= passwordController.text;

    try{
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email, 
        password: password);
      Navigator.pushNamed(context, '/home'); //navigate to home screen
    }on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? 'Login failed'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(

        padding: EdgeInsets.symmetric(vertical: 10),              //padding
        width: double.infinity,
        decoration: const BoxDecoration(                        //background
          gradient: LinearGradient(               //gradient 
            begin: Alignment.topCenter,
            colors: [
              Colors.blue,
              Color.fromARGB(255, 13, 97, 241),
              Color.fromARGB(255, 3, 56, 146),
            ],
          ),
        ),
        child: Column(                                  //column
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 10), 
            Padding(padding: EdgeInsets.all(10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,  //alignment
              children: [
                           
              Image(image: AssetImage("assets/ledgr.png"),width: 200,height: 100, ), //title

               //subtitle
              ],       
            )
            ), 
            SizedBox(height: 10),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(50),
                    topRight: Radius.circular(50),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.all(30),
                  child: Column(
                    children: [
                      Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [BoxShadow(
                            color: Color.fromRGBO(27, 136, 225, 0.298),
                            blurRadius: 20,
                            offset: Offset(0, 10)
                          )
                          ]
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: TextFormField(   
                                //controller: emailController,       //email input
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: 'Email',
                                  prefixIcon: Icon(Icons.email, color: Colors.blue),
                                  contentPadding: EdgeInsets.all(15),
                                ),
                              ), 
                            ),
                            SizedBox(height: 15,),
                            Container(
                              padding: EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: TextFormField(          //password input
                                //controller: passwordController,
                                obscureText: true,
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: 'Password',
                                  prefixIcon: Icon(Icons.lock, color: Colors.blue),
                                  contentPadding: EdgeInsets.all(15),
                                ),
                              ), 
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 40,),
                      Text('Forgot Password?', style: TextStyle(color: Colors.blue, fontSize: 16)), //forgot password
                      SizedBox(height: 20,),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/home'); //navigate to home screen
                        },                 //login button
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text('Login', style: TextStyle(fontSize: 18, color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              ),
            )
          ]
        ),
      ),
    );
  }
}