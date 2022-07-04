
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_beep/flutter_beep.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';

import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:restro_simplify/controller/TimeController.dart';
import 'package:shared_preferences/shared_preferences.dart';


import 'editpos.dart';
import 'package:flutter/services.dart';

class OrderScreen extends StatefulWidget {
  const OrderScreen({Key? key, this.data}) : super(key: key);

  final data;

  @override
  _OrderScreenState createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  final url = "http://192.168.1.1/restroms/api";

  List? orders = [];
  int count = 0;

  Future<String> getOrderData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var id = prefs.get("userid");

    final response =
        await http.get(Uri.parse(url + "/tableOrders/getUnpaidOrders/$id"));
        print(response.statusCode);
        print(response.body);
    if (response.statusCode == 200) {
      var jsonData = json.decode(response.body);

      if (mounted) {
        setState(() {
          orders = jsonData['data'];
          count = orders!.length;
        });
        if (kDebugMode) {
          print(orders);
        }
      }

      return "success";
    } else {
      throw Exception('Failed to load data');
    }
  }

  Future<String> _billRequest(orderId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var id = prefs.get("userid");
    final response = await http
        .get(Uri.parse(url + "/tableOrders/requestBill/$id/$orderId"));

    if (response.statusCode == 200) {
     showToast(
           "Bill Successfully Requested",
            context: context,
                                  position: StyledToastPosition.center,  
                                    duration: const Duration(seconds: 2),
          backgroundColor: Colors.green);
      getOrderData();
      return "success";
    } else {
      throw Exception('Failed to load data');
    }
  }

  @override
  void initState() {
    getOrderData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // Set landscape orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    return Scaffold(
        body: count == 0
            ? GestureDetector(
                onTap: () {
                  Globals.timer?.cancel();
                  Globals.checkTime(context);
                },
                child: const Center(
                  child: Center(
                    child: Text("No Orders Yet!"),
                  ),
                ),
              )
            : ListView(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Align(
                      alignment: Alignment.center,
                      child: Text(
                        "Current Running Tables : " + count.toString(),
                        style: const TextStyle(
                            color: Colors.blueGrey,
                            fontWeight: FontWeight.bold,
                            fontSize: 18),
                      ),
                    ),
                  ),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const ScrollPhysics(),
                    crossAxisCount: 7,
                    children: orders!.map((data) {
                      return InkWell(
                        onLongPress: () {
                         
                           FlutterBeep.beep();
                          _neverSatisfied(data['id'], data['user_id'])
                              .then((value) {});
                        },
                        child: Card(
                          color: data['is_printed'] == '0'
                              ? Colors.blueGrey
                              : Colors.blueGrey[300],
                          child: InkWell(
                            onTap: () async {
                              Globals.timer?.cancel();
                              Globals.checkTime(context);
                              // var res = await http.get
                              // ('https://jsonplaceholder.typicode.com/photos');
                              var res = await http.get(Uri.parse(url +
                                  '/tableOrders/' +
                                  widget.data['id'] +
                                  '/' +
                                  data['id']));

                              if (res.statusCode == 200) {
                                Navigator.of(context)
                                    .push(MaterialPageRoute(builder: (context) {
                                  return EditPosScreen(
                                      orderId: data['id'], data: widget.data);
                                }));
                              } else if (res.statusCode == 406) {
                                var message = json.decode(res.body)['message'];
                               showToast(
                                   message,
                                    context: context,
                                  position: StyledToastPosition.center,  
                                    duration: const Duration(seconds: 2),
                                    backgroundColor: Colors.green);
                              } else if (res.statusCode == 401) {
                                var message = json.decode(res.body)['message'];
                               showToast(
                                    message,
                                     context: context,
                                  position: StyledToastPosition.center,  
                                    duration: const Duration(seconds: 2),
                                    backgroundColor: Colors.orange);
                              }
                            },
                            child: Align(
                              alignment: Alignment.center,
                              child: Container(
                                margin: const EdgeInsets.only(top: 5),
                                child: Column(
                                  children: <Widget>[
                                    const Padding(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 35.0),
                                      child: SizedBox(
                                          width: 40.0,
                                          child: Icon(
                                            Icons.table_bar,
                                            size: 35,
                                            color: Colors.white,
                                          )),
                                    ),
                                    Text(
                                      data['table_name'],
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 13),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 4.0),
                                      child: Text(
                                        data['order_created_time'],
                                        style: const TextStyle(
                                            color: Colors.white, fontSize: 13),
                                      ),
                                    ),
                                    Container(
                                      margin: const EdgeInsets.only(top: 5),
                                      child: Align(
                                        alignment: Alignment.bottomCenter,
                                        child: Card(
                                          color: Colors.blueGrey[200],
                                          elevation: 0,
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text(
                                              "Rs.${data['net_amount']}",
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ));
  }

  Future<void> _neverSatisfied(orderId, userId) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Do you want to request bill print?'),
          actions: <Widget>[
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                primary: Colors.blue[400],
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () async {
                Globals.timer?.cancel();
                Globals.checkTime(context);
                Navigator.of(context).pop();
              },
            ),
            // RaisedButton(
            //     color: Color(0xFFcc471b),
            //     onPressed: () {
            //       Navigator.push(
            //           context,
            //           MaterialPageRoute(
            //               builder: (context) =>
            //                   FonepayPage(orderID: orderId, userID: userId)));
            //     },
            //     child: Text('Fone Pay')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                primary: Colors.blue[800],
              ),
              child: const Text(
                'Request Bill',
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () async {
                Globals.timer?.cancel();
                Globals.checkTime(context);
                await _billRequest(orderId);
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );
  }
}
