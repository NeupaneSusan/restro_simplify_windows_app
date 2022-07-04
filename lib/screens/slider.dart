import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:restro_simplify/controller/TimeController.dart';
import 'package:restro_simplify/controller/sliderlistController.dart';
import 'package:wakelock/wakelock.dart';

class MySlider extends StatefulWidget {
  const MySlider({Key? key}) : super(key: key);

  @override
  State<MySlider> createState() => _MySliderState();
}

class _MySliderState extends State<MySlider> {
  @override
  void initState() {
    Wakelock.enable();
    super.initState();
  }

  @override
  void dispose() {
    Wakelock.enable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;
    return WillPopScope(
      onWillPop: () async {
        Globals.timer!.cancel();
        Globals.checkTime(context);
        Navigator.pop(context);
        return false;
      },
      child: Scaffold(
        body: Stack(
          children: [
            Consumer<SliderListController>(
              builder: (context,data,child) {
                return CarouselSlider(
                  options: CarouselOptions(
                      autoPlay: true,
                      autoPlayInterval: const Duration(seconds: 5),
                      height: height),
                  items:data.slider.map((i) {
                    return Builder(
                      builder: (BuildContext context) {
                        return Container(
                            width: width,
                            margin: const EdgeInsets.symmetric(horizontal: 5.0),
                            decoration: const BoxDecoration(color: Colors.white),
                            child: Image.memory(
                              i.image!
                            ));
                      },
                    );
                  }).toList(),
                );
              }
            ),
             Positioned(
              top:5,
              left:15.0,
              child: IconButton(
               onPressed: () {
                  Globals.timer!.cancel();
                  Globals.checkTime(context);
                  Navigator.pop(context);
                },
                icon: const Icon( Icons.arrow_back,color: Colors.black,))),
          ],
        ),
      ),
    );
  }
}
