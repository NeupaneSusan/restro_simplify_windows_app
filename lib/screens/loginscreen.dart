// ignore_for_file: prefer_typing_uninitialized_variables

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';

import 'package:package_info_plus/package_info_plus.dart';
import 'package:restro_simplify/controller/TimeController.dart';
import 'package:restro_simplify/screens/checkLogin.dart';

import '../models/login.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key, this.title, this.urls}) : super(key: key);

  final String? title;
  final urls;
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  TextEditingController email = TextEditingController();
  String versionName = '';
  bool isOnline = true;
  bool isLoading = false;

  final url = "http://192.168.1.1/restroms/api";
  final checkurl =
      Uri.parse("http://192.168.1.1/restroms/api/daySettings/checkDayStatus");
  var urls;
  var userData;
  var data = Login();

  TextEditingController password = TextEditingController();
  addUserToLocalStorage(data) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('isLogin', true);
    prefs.setString('floorId', data['floor_id']);

    prefs.setString('user', json.encode(data));
  }

  Future<bool> createUser({Map<String, dynamic>? body}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    try {
      final response =
          await http.post(Uri.parse(url + '/auth/login'), body: body);

      var jsonData = json.decode(response.body);

      if (response.statusCode != 401) {
        setState(() {
          userData = jsonData['userInfo'];
          data = Login(
              id: userData['id'],
              username: userData['username'],
              email: userData['email'],
              storeId: userData['store_id'],
              displayName: userData['display_name']);
          addUserToLocalStorage(userData);
          prefs.setString('userid', userData['id']);
          isLoading = false;
          Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (BuildContext context) {
            return const CheckLogin();
          }));
        });

        return true;
      } else {
        showToast("Credentials doesnot matched!",
            context: context,
            position: StyledToastPosition.center,
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.red);
        setState(() {
          isLoading = false;
        });
        return false;
      }
    } on SocketException {
      showToast("System is Offline",
          context: context,
          position: StyledToastPosition.center,
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.red);
      setState(() {
        isLoading = false;
        isOnline = false;
      });
      return false;
    }
  }

  getVersion() async {
    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      final response = await http.get(checkurl);
      if (response.statusCode == 200) {
        setState(() {
          isOnline = true;
          versionName = packageInfo.version;
        });
      } else {
        setState(() {
          isOnline = false;
          versionName = packageInfo.version;
        });
      }
    } catch (error) {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        isOnline = false;
        versionName = packageInfo.version;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    getVersion();
  }

  TextStyle style = const TextStyle(fontFamily: 'Montserrat', fontSize: 20.0);

  Future<bool?> _alert() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Do you really want to exit app ?'),
          actions: <Widget>[
            TextButton(
              child: const Text('No'),
              onPressed: () {
                Navigator.pop(context, false);
              },
            ),
            TextButton(
              child: const Text('Yes'),
              onPressed: () {
                SystemNavigator.pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
// Set landscape orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    return WillPopScope(
      onWillPop: (() => _alert().then((value) => value!)),
      child: GestureDetector(
        child: Scaffold(
            backgroundColor: Colors.blueGrey,
            body: ListView(
              children: <Widget>[
                Container(
                  height: 577.0,
                  width: 100.0,
                  color: Colors.white,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(
                        36.0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Column(
                              children: [
                                Container(
                                  height: 20.0,
                                  width: 20.0,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(50),
                                    color: isOnline == true
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                ),
                                const SizedBox(
                                  height: 5.0,
                                ),
                                Text(isOnline == true ? 'Online' : 'Offline',
                                    style: const TextStyle(fontSize: 15)),
                              ],
                            ),
                          ),
                          const SizedBox(
                            height: 45.0,
                          ),
                          const Text(
                            "Restro Simplify",
                            style: TextStyle(fontSize: 35, color: Colors.teal),
                          ),
                          const SizedBox(height: 30.0),
                          SizedBox(
                              width: 400,
                              child: TextFormField(
                                onChanged: ((value) {
                                  Globals.timer!.cancel();
                                  Globals.checkTime(context);
                                }),
                                controller: email,
                                obscureText: false,
                                style: style,
                                decoration: InputDecoration(
                                    labelText: "Email",
                                    contentPadding: const EdgeInsets.fromLTRB(
                                        20.0, 15.0, 20.0, 15.0),
                                    border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(32.0))),
                              )),
                          const SizedBox(height: 25.0),
                          SizedBox(
                            width: 400,
                            child: TextFormField(
                              onChanged: (value) {
                                Globals.timer!.cancel();
                                Globals.checkTime(context);
                              },
                              controller: password,
                              obscureText: true,
                              style: style,
                              decoration: InputDecoration(
                                  labelText: "Password",
                                  contentPadding: const EdgeInsets.fromLTRB(
                                      20.0, 15.0, 20.0, 15.0),
                                  border: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(32.0))),
                            ),
                          ),
                          const SizedBox(
                            height: 35.0,
                          ),
                          isOnline == true
                              ? Material(
                                  elevation: 5.0,
                                  borderRadius: BorderRadius.circular(30.0),
                                  color: Colors.blueGrey,
                                  child: SizedBox(
                                    width: 200,
                                    child: MaterialButton(
                                      padding: const EdgeInsets.fromLTRB(
                                          20.0, 15.0, 20.0, 15.0),
                                      onPressed: () async {
                                        Globals.timer!.cancel();
                                        Globals.checkTime(context);
                                        FocusScope.of(context)
                                            .requestFocus(FocusNode());
                                        if (email.text.isEmpty ||
                                            password.text.isEmpty) {
                                          showToast("Credentials must required",
                                              context: context,
                                              position:
                                                  StyledToastPosition.center,
                                              duration:
                                                  const Duration(seconds: 2),
                                              backgroundColor: Colors.red);
                                        } else {
                                          setState(() {
                                            isLoading = true;
                                          });
                                          Login newUser = Login(
                                              email: email.text,
                                              password: password.text);

                                          await createUser(
                                              body: newUser.toMap()
                                                  as Map<String, dynamic>?);
                                        }
                                      },
                                      child: !isLoading
                                          ? Text("Login",
                                              textAlign: TextAlign.center,
                                              style: style.copyWith(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold))
                                          : const CircularProgressIndicator(),
                                    ),
                                  ),
                                )
                              : const Text(''),
                          const SizedBox(
                            height: 30.0,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const SizedBox(
                                height: 25.0,
                                child: Text(
                                  "Powered By: Lumbini Tech Service Pvt. Ltd",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.teal,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              SizedBox(
                                child: Text(
                                  "v" + versionName,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.teal,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            )),
      ),
    );
  }

  _showDialog(title, text) {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(title),
            content: Text(text),
            actions: <Widget>[
              TextButton(
                child: const Text('Ok'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              )
            ],
          );
        });
  }
}
