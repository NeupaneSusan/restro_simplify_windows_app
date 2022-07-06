// ignore_for_file: prefer_typing_uninitialized_variables

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:restro_simplify/controller/CartController.dart';
import 'package:restro_simplify/controller/TimeController.dart';
import 'package:restro_simplify/controller/audio_controller.dart';
import 'package:restro_simplify/models/floor.dart';
import 'package:restro_simplify/screens/loginscreen.dart';
import 'package:restro_simplify/screens/paidorders.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class ProfileScreen extends StatefulWidget {
  final data;
  final Uint8List bytes;
  const ProfileScreen({Key? key, this.data, required this.bytes})
      : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool isLoading = false;
  final url = Uri.parse("http://192.168.1.1/restroms/api/floors");
  final changeFloorUrl =
      Uri.parse('http://192.168.1.1/restroms/api/floors/switch');
  List<Floor> floor = [];
  var floorId;
  getFloorId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var floorid = prefs.getString('floorId');

    setState(() {
      floorId = floorid;
    });
  }

  Future fetchFloor() async {
    List<Floor> cats = [];
    var res = await http.get(url);
    if (res.statusCode == 200) {
      var jsonData = jsonDecode(res.body)['data'];
      for (var data in jsonData) {
        cats.add(Floor.fromJson(data));
      }
      if (mounted) {
        setState(() {
          floor = cats;
        });
      }

      return 'success';
    } else {
      throw "Can't get floor";
    }
  }

  changeFloor(id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var userId = prefs.getString('userid');

    Map<String, String> header = {
      'Content-type': 'application/json',
      'Accept': 'application/json',
    };
    var body = jsonEncode(<String, dynamic>{"floor_id": id, "user_id": userId});
    var response = await http.post(changeFloorUrl, headers: header, body: body);

    if (response.statusCode == 200) {
      prefs.remove('floorId');
      setState(() {
        prefs.setString('floorId', id.toString());
        floorId = id;
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    fetchFloor();
    getFloorId();
    super.initState();
  }

  _onTapImage(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        Image.memory(
          widget.bytes,
          fit: BoxFit.contain,
        ), // Show your Image
        Align(
          alignment: Alignment.topRight,
          child: ElevatedButton.icon(
              onPressed: () {
                Globals.timer?.cancel();
                Globals.checkTime(context);
                Navigator.pop(context);
              },
              icon: const Icon(
                Icons.close,
                color: Colors.white,
              ),
              label: Text('Close')),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SafeArea(
            child: Container(
      margin: const EdgeInsets.only(top: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 15.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ElevatedButton.icon(
                      style: TextButton.styleFrom(
                          backgroundColor: Colors.blueGrey,
                          primary: Colors.white),
                      onPressed: () {
                        Globals.timer?.cancel();
                        Globals.checkTime(context);
                        showDialog(
                            context: context,
                            builder: (context) =>
                                _onTapImage(context)); // Call the Dialog.
                      },
                      icon: const Icon(
                        Icons.qr_code,
                        size: 30.0,
                      ),
                      label: const Text(
                        'Scan For Payment',
                        style: TextStyle(fontSize: 20),
                      )),
                  const SizedBox(
                    height: 20,
                  ),
                  ElevatedButton.icon(
                      style: TextButton.styleFrom(
                          backgroundColor: Colors.blueGrey),
                      onPressed: () {
                        Globals.timer?.cancel();
                        Globals.checkTime(context);
                        showDialog(
                            context: context,
                            builder: (context) {
                              return PaidOrders(data: widget.data);
                            }); // Call the Dialog.
                      },
                      icon: const Icon(
                        Icons.attach_money,
                        size: 30,
                      ),
                      label: const Text(
                        'Settled Bill',
                        style: TextStyle(fontSize: 20),
                      )),
                ],
              ),
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : Column(
                    children: <Widget>[
                      Column(
                        children: [
                          const CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.blueGrey,
                            child: Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 50,
                            ),
                          ),
                          ListTile(
                              title: Center(
                            child: Text("${widget.data['display_name']}",
                                style: const TextStyle(
                                    color: Colors.blueGrey,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 20.0)),
                          )),
                          // Row(children: [
                          //   Column(
                          //     children: [
                          //       Text('wORKING'),

                          //     ],
                          //   )
                          // ],),
                          floor.isNotEmpty
                              ? Column(
                                  children: [
                                    const SizedBox(
                                      height: 10.0,
                                    ),
                                    const Text(
                                      'Switch the Floor',
                                      style: TextStyle(
                                          color: Colors.blueGrey,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 20.0),
                                    ),
                                    const SizedBox(
                                      height: 15.0,
                                    ),
                                    Container(
                                      margin: const EdgeInsets.all(8.0),
                                      height: 70.0,
                                      child: Center(
                                        child: ListView.builder(
                                            shrinkWrap: true,
                                            scrollDirection: Axis.horizontal,
                                            itemCount: floor.length,
                                            itemBuilder: (context, int i) {
                                              return InkWell(
                                                onTap: () {
                                                  Globals.timer?.cancel();
                                                  Globals.checkTime(context);
                                                   final myAudio = MyAudio();
              myAudio.playSound();
            
                                                  if (floorId != floor[i].id) {
                                                    changeFloor(floor[i].id);
                                                    setState(() {
                                                      isLoading = true;
                                                    });
                                                  }
                                                },
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          left: 8.0),
                                                  child: Container(
                                                      // height: 20.0,
                                                      width: 70.0,
                                                      decoration: BoxDecoration(
                                                          shape:
                                                              BoxShape.circle,
                                                          color: floorId ==
                                                                  floor[i].id
                                                              ? Colors.green
                                                              : Colors.grey,
                                                          border: Border.all(
                                                              width: 2,
                                                              color: floorId ==
                                                                      floor[i]
                                                                          .id
                                                                  ? Colors.green
                                                                  : Colors
                                                                      .white)),
                                                      child: Center(
                                                          child: Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(7.0),
                                                        child: Text(
                                                          floor[i].name!,
                                                          style:
                                                              const TextStyle(
                                                                  fontSize:
                                                                      13.0,
                                                                  color: Colors
                                                                      .white),
                                                        ),
                                                      ))),
                                                ),
                                              );
                                            }),
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 30.0,
                                    ),
                                  ],
                                )
                              : Container(),
                          SizedBox(
                            height: 40,
                            width: 200,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                primary: Colors.blueGrey,
                              ),
                              child: const Text(
                                "Logout",
                                style: TextStyle(
                                    color: Colors.white, fontSize: 18.0),
                              ),
                              onPressed: () {
                                Globals.timer?.cancel();
                                Globals.checkTime(context);
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: const Text("You want to logout?"),
                                      content: const Text("Are you sure?"),
                                      actions: <Widget>[
                                        TextButton(
                                          child: const Text("Yes"),
                                          onPressed: () async {
                                            Globals.timer?.cancel();
                                            Globals.checkTime(context);
                                            final cartContoller =
                                                Provider.of<CartController>(
                                                    context,
                                                    listen: false);
                                            SharedPreferences
                                                sharedPreferences =
                                                await SharedPreferences
                                                    .getInstance();
                                            sharedPreferences.remove('isLogin');
                                            sharedPreferences.remove('userid');
                                            sharedPreferences.remove('user');
                                            sharedPreferences.clear();
                                            cartContoller.clear();
                                            Navigator.of(context).pushReplacement(
                                                MaterialPageRoute(
                                                    builder: (BuildContext
                                                            context) =>
                                                        const LoginScreen()));
                                          },
                                        ),
                                        TextButton(
                                          child: const Text("Cancel"),
                                          onPressed: () {
                                            Globals.timer?.cancel();
                                            Globals.checkTime(context);
                                            Navigator.of(context).pop();
                                          },
                                        ),
                                      ],
                                    );
                                  },
                                );
                                //
                              },
                            ),
                          )
                        ],
                      )
                    ],
                  ),
          ),
          Expanded(
              child: Column(
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(
                        text: 'Working Hours: ',
                        style: TextStyle(
                            color: Colors.blueGrey,
                            fontWeight: FontWeight.w600,
                            fontSize: 20.0)),
                    TextSpan(
                        text: '${widget.data['total_working_hours']}',
                        style: const TextStyle(
                            color: Colors.blueGrey,
                            fontWeight: FontWeight.w600,
                            fontSize: 20.0))
                  ],
                ),
              ),
              const SizedBox(
                height: 10.0,
              ),
              Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(
                        text: 'Reward Point: ',
                        style: TextStyle(
                            color: Colors.blueGrey,
                            fontWeight: FontWeight.w600,
                            fontSize: 20.0)),
                    TextSpan(
                        text: '${widget.data['reward_points']}',
                        style: const TextStyle(
                            color: Colors.blueGrey,
                            fontWeight: FontWeight.w600,
                            fontSize: 20.0))
                  ],
                ),
              ),
            ],
          )),
          Container(
            width: 100.0,
          ),
        ],
      ),
    )));
  }
}
