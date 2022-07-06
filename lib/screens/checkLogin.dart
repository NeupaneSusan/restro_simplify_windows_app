import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';

import 'package:http/http.dart' as http;
import 'package:restro_simplify/screens/firstScreen.dart';
import 'package:restro_simplify/screens/loginscreen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CheckLogin extends StatefulWidget {
  const CheckLogin({Key? key}) : super(key: key);

  @override
  State<CheckLogin> createState() => _CheckLoginState();
}

class _CheckLoginState extends State<CheckLogin> {
  bool isOnline = true;
  var client = HttpClient();
  var userData;
  @override
  void initState() {
    super.initState();
    getUserFromLocalStorage();
  }

  Future<ByteData> getImageBytesData(Uri key) async {
    final HttpClientRequest request = await client.getUrl(key);
    final HttpClientResponse response = await request.close();
    if (response.statusCode != HttpStatus.ok) {
      Uint8List bytes = Uint8List.fromList([]);
      return bytes.buffer.asByteData();
    }
    final Uint8List bytes = await consolidateHttpClientResponseBytes(response);
    return bytes.buffer.asByteData();
  }

  void getUserFromLocalStorage() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      bool data = prefs.getBool('isLogin') ?? false;
      if (data) {
        final res = await http
            .get(Uri.parse('http://192.168.1.1/restroms/api/qrcodes/fonepay'));
        if (res.statusCode == 200) {
          var jsonData = jsonDecode(res.body)['qrcode'];
          final ByteData imageData =
              await getImageBytesData(Uri.parse(jsonData));
          Uint8List bytes = imageData.buffer.asUint8List();
          userData = json.decode(prefs.getString('user')!);
          Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (BuildContext context) {
            return MyFirstScreen(
              userData: userData,
              imageByte: bytes,
            );
          }));
        } else {
          Uint8List bytes = Uint8List.fromList([]);
          userData = json.decode(prefs.getString('user')!);
          Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (BuildContext context) {
            return MyFirstScreen(
              userData: userData,
              imageByte: bytes,
            );
          }));
        }
      } else {
        Navigator.of(context)
            .pushReplacement(MaterialPageRoute(builder: (BuildContext context) {
          return const LoginScreen();
        }));
      }
    } catch (error) {
      showToast("No internet",
          context: context,
          position: StyledToastPosition.center,
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.red);
      setState(() {
        isOnline = false;
      });
    }
  }

  Widget build(BuildContext context) {
    return isOnline
        ? Text('')
        : Center(
            child: Text("No internate"),
          );
  }
}
