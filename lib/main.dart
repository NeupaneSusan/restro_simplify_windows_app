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
        ChangeNotifierProvider(create: (context) => SliderListController())
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
  @override
  void initState() {
    super.initState();
    Globals.timer?.cancel();
    Globals.checkTime(context);
    getImageForSlider();
  }

  readImage(image) async {
    final ByteData imageData =
        await NetworkAssetBundle(Uri.parse(image)).load("");
    Uint8List bytes = imageData.buffer.asUint8List();
    return bytes;
  }

  void getImageForSlider() async {
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerCancel: (event) {
            Globals.timer?.cancel();
            Globals.checkTime(context);
          },
          onPointerDown: (event) {
            Globals.timer?.cancel();
            Globals.checkTime(context);
          },
          onPointerHover: (event) {
            Globals.timer?.cancel();
            Globals.checkTime(context);
          },
          onPointerMove: (event) {
            Globals.timer?.cancel();
            Globals.checkTime(context);
          },
          child: const CheckLogin()),
    );
  }
}
