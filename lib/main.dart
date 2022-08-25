import 'dart:convert';

import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:flutter/services.dart';
import 'package:restro_simplify/controller/TimeController.dart';
import 'package:restro_simplify/controller/sliderlistController.dart';
import 'package:restro_simplify/models/slider.dart';
import 'package:restro_simplify/screens/checkLogin.dart';

import 'controller/CartController.dart';
import 'package:desktop_window/desktop_window.dart' as window_size;
import 'dart:io';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    window_size.DesktopWindow.getFullScreen();
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => CartController()),
        ChangeNotifierProvider(create: (context) => SliderListController()),
        ChangeNotifierProvider(create: (context) => TimeController()),
      ],
      child: MaterialApp(
        navigatorKey: Globals.navigatorKey,
        title: "RestroMS",
        debugShowCheckedModeBanner: false,
        home: const ContainerPage(),
      ),
    );
  }
}

class ContainerPage extends StatefulWidget {
  const ContainerPage({Key? key}) : super(key: key);

  @override
  State<ContainerPage> createState() => _ContainerPageState();
}

class _ContainerPageState extends State<ContainerPage> {
  bool isLoading = true;
  bool isNet = true;
  @override
  void initState() {
    super.initState();
    readApi();
  }

  readApi() {
    getImageForSlider();
    getSliderTime();
  }

  readImage(image) async {
    final ByteData imageData =
        await NetworkAssetBundle(Uri.parse(image)).load("");
    Uint8List bytes = imageData.buffer.asUint8List();
    return bytes;
  }

  void getImageForSlider() async {
    try {
      final sliderProvider =
          Provider.of<SliderListController>(context, listen: false);
      List<SliderModel> sliderlist = [];
      var res = await http
          .get(Uri.parse('http://192.168.1.1/restroms/api/medias/sliders'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body)['data'];
        for (var result in data) {
          var image = await readImage(result['image']);
          result['image'] = image;
          sliderlist.add(SliderModel.fromJson(result));
        }
        sliderProvider.setSliderList(sliderlist);
      }
    } catch (error) {}
  }

  getSliderTime() async {
    try {
      final timeValue = Provider.of<TimeController>(context, listen: false);
      final response = await http
          .get(Uri.parse("http://192.168.1.1/restroms/api/system/settings"));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)["data"];
        timeValue.timeValue = data["slideshow_timer"];
        setState(() {
          isLoading = false;
        });
      } else{

      }
    } catch (e) {
      print("Socket exception: ${e}");
      if (e is SocketException) {
           showDialogs(e.message);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return isLoading ? Scaffold() : CheckLogin();
  }

showDialogs (message){
  return showDialog(
   context: context,
   builder: (BuildContext context) {
     return AlertDialog(
       title: Text('${message}'),
       actions: <Widget>[
         TextButton(
           child: const Text('No'),
           onPressed: () {
             Navigator.pop(context, false);
             Future.delayed(const Duration(seconds: 2), () {
               readApi();
             });
           },
         ),
       ],
     );
   },
 );
}
}