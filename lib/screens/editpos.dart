// ignore_for_file: prefer_typing_uninitialized_variables

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:connectivity/connectivity.dart';
import 'package:flutter/services.dart';

import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:provider/provider.dart';
import 'package:restro_simplify/controller/CartController.dart';
import 'package:restro_simplify/controller/TimeController.dart';
import 'package:restro_simplify/controller/audio_controller.dart';
import 'package:restro_simplify/dialog/product_dialog.dart';
import 'package:restro_simplify/screens/homescreen.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/Category.dart';

import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;

class EditPosScreen extends StatefulWidget {
  const EditPosScreen({Key? key, this.data, this.orderId}) : super(key: key);

  final data, orderId;

  @override
  _EditPosScreenState createState() => _EditPosScreenState();
}

class _EditPosScreenState extends State<EditPosScreen> {
  TextEditingController guestController = TextEditingController();
  TextEditingController remarksController = TextEditingController();
  TextEditingController filterController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<Category> categories = <Category>[];

  List<Category> _searchResult = [];

  Category? selectedCategory;

  int _isButtonDisabled = 1;
//  final url = "http://d163f8b8ae8d.ngrok.io/restroms/api";
  final url = "http://192.168.1.1/restroms/api";
  final imgUrl = "http://192.168.1.1/restroms/";

  Future<String> fetchCategories() async {
    var res = await http.get(Uri.parse(url + '/categories'));
    if (res.statusCode == 200) {
      var jsonData = jsonDecode(res.body);

      List<Category> cats = [];
      for (var data in jsonData) {
        cats.add(Category.fromJson(data));
      }
      setState(() {
        categories = cats;
        _searchResult = categories;
      });
      return 'success';
    } else {
      throw "Can't get categories.";
    }
  }

  //fetch products

// toast
  void toast(message, color) {
    showToast(message,
        context: context,
        position: StyledToastPosition.center,
        duration: const Duration(seconds: 2),
        backgroundColor: color);
  }

  var oldOrder;
  var totalUpdate;
  List<dynamic>? oldOrderItems;
  double discount = 0.0;

  Future<String> fetchOrder(userId, orderId) async {
    CartController model = Provider.of<CartController>(context, listen: false);
    model.clear();
    var res = await http
        .get(Uri.parse(url + '/tableOrders/edit/' + userId + '/' + orderId));
    if (res.statusCode == 200) {
      var jsonData = json.decode(res.body);
      setState(() {
        totalUpdate = jsonData["total_update"];
        oldOrder = jsonData['data'];
        oldOrderItems = oldOrder['order_items'];
        guestController.text = oldOrder['no_of_guest'];
        discount = double.parse(jsonData['data']['discount']);
        _isButtonDisabled = 0;
      });

      for (var order in oldOrderItems!) {
        Provider.of<CartController>(context, listen: false).addOldItem(
            order['product_id'],
            order['name'],
            double.parse(order['rate']),
            int.parse(order['product_store_id']),
            int.parse(order['qty']));
      }

      return 'success';
    } else {
      throw "Can't get products.";
    }
  }

  // post address
  Future<bool> checkout({var body, cart}) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    var userid = preferences.get('userid')!;

    setState(() {
      _isButtonDisabled = 1;
    });

    Map<String, String> header = {
      'Content-type': 'application/json',
      'Accept': 'application/json',
    };

    var res = await http.put(
      Uri.parse(
          url + '/tableOrders/' + (userid as String) + '/' + oldOrder['id']),
      headers: header,
      body: body,
    );
    print(res.statusCode);
    if (res.statusCode == 200) {
      toast("Order Updated Successfully", Colors.green);
      cart.clear();
      guestController.text = 0.toString();
      // Navigator.push(context, MaterialPageRoute(builder: (context) {
      // return HomeScreen(
      // selectedTable: null,
      // );
      // }));
      setState(() {
        _isButtonDisabled = 0;
      });
      return true;
    } else if (res.statusCode == 503) {
      var message = json.decode(res.body)['message'];
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              content: Text(message),
              actions: <Widget>[
                const SizedBox(width: 20.0),
                TextButton(
                    child: const Text("Close"),
                    onPressed: () {
                      Globals.timer?.cancel();
                      Globals.checkTime(context);
                      Navigator.of(context).pop();
                      cart.clear();
                      // Navigator.push(context,
                      // MaterialPageRoute(builder: (context) {
                      // return HomeScreen(
                      // selectedTable: null,
                      // );
                      // }));
                    }),
                const SizedBox(width: 180.0),
              ],
            );
          });

      setState(() {
        _isButtonDisabled = 0;
      });
      return false;
    } else {
      var message = json.decode(res.body)['message'];
      toast(message, Colors.green);
      setState(() {
        _isButtonDisabled = 0;
      });
      return false;
    }
  }

  // check internet
  internetChecker() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.mobile ||
        connectivityResult == ConnectivityResult.wifi) {
      GestureDetector(
          onTap: () {
            Globals.timer?.cancel();
            Globals.checkTime(context);
          },
          child: const EditPosScreen());
    } else {
      Scaffold(
        key: _scaffoldKey,
        body: const Center(
          child: Text("No Internet Connection"),
        ),
      );
    }
  }

  //search result
  onSearchTextChanged(String text) async {
    List<Category> myList = text.isEmpty
        ? categories
        : categories
            .where((p) => p.name.toLowerCase().contains(text.toLowerCase()))
            .toList();

    setState(() {
      _searchResult = myList;
    });
  }

  @override
  void initState() {
    fetchCategories();
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchOrder(widget.data['id'], widget.orderId);
    });
  }

  checkIsnew(check) {
    check.forEach((element) {
      if (element['is_new'] == 1) {
        return true;
      }
      return false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Set landscape orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    return Listener(
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
      child: Consumer<CartController>(builder: (context, cart, child) {
        return Scaffold(
            key: _scaffoldKey,
            body: SingleChildScrollView(
              child: SizedBox(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                child: GestureDetector(
                  onTap: () {
                    Globals.timer?.cancel();
                    Globals.checkTime(context);
                    FocusScope.of(context).requestFocus(FocusNode());
                  },
                  child: SafeArea(
                      child: Container(
                    margin: const EdgeInsets.only(
                        top: 5, left: 5, right: 5, bottom: 0),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 6,
                          child: Card(
                            elevation: 5,
                            child: Container(
                              decoration: const BoxDecoration(
                                  color: Colors.white,
                                  border: Border(
                                      top: BorderSide(
                                          color: Colors.teal, width: 5))),
                              child: Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: Row(
                                      children: [
                                        IconButton(
                                            onPressed: () {
                                              Globals.timer?.cancel();
                                              Globals.checkTime(context);
                                              final myAudio = MyAudio();
                                              Navigator.of(context).pop(true);
                                              myAudio.playSound();
                                            },
                                            icon: const Icon(Icons.arrow_back)),
                                        const SizedBox(width: 10),
                                        Container(
                                            width: 100,
                                            height: 35,
                                            decoration: BoxDecoration(
                                                color: Colors.teal,
                                                border: Border.all(
                                                    color: Colors.grey)),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Center(
                                                  child: Text(
                                                oldOrder != null
                                                    ? oldOrder['table_name']
                                                    : '',
                                                style: const TextStyle(
                                                    color: Colors.white),
                                              )),
                                            )),
                                        const SizedBox(width: 10),
                                        Expanded(
                                            child: Row(
                                          children: [
                                            Container(
                                              height: 28,
                                              width: 40,
                                              decoration: BoxDecoration(
                                                  border: Border.all(
                                                      width: 0.0,
                                                      color: Colors.grey)),
                                              child: const Padding(
                                                padding: EdgeInsets.all(1.0),
                                                child: Icon(
                                                  Icons.edit,
                                                  size: 16,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ),
                                            Flexible(
                                              child: TextFormField(
                                                controller: remarksController,
                                                decoration:
                                                    const InputDecoration(
                                                  fillColor: Colors.white30,
                                                  isDense: true,
                                                  contentPadding:
                                                      EdgeInsets.all(8),
                                                  hintText: 'Remarks',

                                                  // border: Border.all(color: Colors.grey)
                                                  border: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.all(
                                                            Radius.circular(
                                                                0.0)),
                                                  ),
                                                  focusedBorder:
                                                      OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius.all(
                                                                  Radius
                                                                      .circular(
                                                                          0.0)),
                                                          borderSide:
                                                              BorderSide(
                                                            color: Colors.grey,
                                                          )),
                                                  enabledBorder:
                                                      OutlineInputBorder(
                                                    borderSide: BorderSide(
                                                      color: Colors.grey,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.all(
                                                            Radius.circular(
                                                                0.0)),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ))
                                      ],
                                    ),
                                  ),
                                  Container(
                                    color: Colors.blueGrey,
                                    child: Padding(
                                      padding: const EdgeInsets.all(6.0),
                                      child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          children: const [
                                            SizedBox(
                                              width: 130,
                                              child: Text(
                                                'Item Name',
                                                style: TextStyle(
                                                    color: Colors.white),
                                              ),
                                            ),
                                            SizedBox(
                                              width: 100,
                                              child: Center(
                                                child: Text(
                                                  'Quantity',
                                                  style: TextStyle(
                                                      color: Colors.white),
                                                ),
                                              ),
                                            ),
                                            SizedBox(
                                              width: 60,
                                              child: Text(
                                                'Price',
                                                style: TextStyle(
                                                    color: Colors.white),
                                              ),
                                            ),
                                            SizedBox(
                                              width: 70,
                                              child: Center(
                                                child: Text(
                                                  'Amount',
                                                  style: TextStyle(
                                                      color: Colors.white),
                                                ),
                                              ),
                                            ),
                                            SizedBox(
                                              width: 20,
                                              child: Text(
                                                'X',
                                                style: TextStyle(
                                                    color: Colors.white),
                                              ),
                                            ),
                                          ]),
                                    ),
                                  ),
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                          color: Colors.grey[100],
                                          border: Border.all(
                                              color: Colors.teal[100]!)),
                                      child: Padding(
                                        padding: const EdgeInsets.all(1.0),
                                        child: ListView.builder(
                                          scrollDirection: Axis.vertical,
                                          itemCount: cart.items.length,
                                          itemBuilder:
                                              (BuildContext context, int i) =>
                                                  Card(
                                            elevation: 1,
                                            color: cart.items.values
                                                        .toList()[
                                                            cart.items.length -
                                                                i -
                                                                1]
                                                        .isNew ==
                                                    1
                                                ? Colors.blueGrey
                                                : Colors.blueGrey[300],
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(1.0),
                                              child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceEvenly,
                                                  children: [
                                                    SizedBox(
                                                      width: 130,
                                                      child: Text(
                                                        cart.items.values
                                                            .toList()[cart.items
                                                                    .length -
                                                                i -
                                                                1]
                                                            .name!,
                                                        style: const TextStyle(
                                                            color:
                                                                Colors.white),
                                                      ),
                                                    ),
                                                    Container(
                                                      decoration: BoxDecoration(
                                                          color: Colors.white38,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      10)),
                                                      width: 100,
                                                      child: Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .spaceBetween,
                                                          children: [
                                                            Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .all(5.0),
                                                              child:
                                                                  GestureDetector(
                                                                onTap: () {
                                                                  Globals.timer
                                                                      ?.cancel();
                                                                  Globals.checkTime(
                                                                      context);

                                                                  final myAudio =
                                                                      MyAudio();
                                                                  myAudio
                                                                      .playSound();
                                                                  if (cart.items
                                                                          .values
                                                                          .toList()[cart.items.length -
                                                                              i -
                                                                              1]
                                                                          .quantity! >
                                                                      cart.items
                                                                          .values
                                                                          .toList()[cart.items.length -
                                                                              i -
                                                                              1]
                                                                          .oldQuantity!) {
                                                                    cart.removeEditSingleItem(cart
                                                                        .items
                                                                        .keys
                                                                        .toList()[cart
                                                                            .items
                                                                            .length -
                                                                        i -
                                                                        1]);
                                                                  }
                                                                },
                                                                child:
                                                                    const Icon(
                                                                  Icons
                                                                      .remove_circle_outline,
                                                                  color: Colors
                                                                      .red,
                                                                ),
                                                              ),
                                                            ),
                                                            Text(cart
                                                                .items.values
                                                                .toList()[cart
                                                                        .items
                                                                        .length -
                                                                    i -
                                                                    1]
                                                                .quantity
                                                                .toString()),
                                                            GestureDetector(
                                                              onTap: () {
                                                                Globals.timer
                                                                    ?.cancel();
                                                                Globals
                                                                    .checkTime(
                                                                        context);

                                                                final myAudio =
                                                                    MyAudio();
                                                                myAudio
                                                                    .playSound();
                                                                // playAudio();
                                                                cart.addItem(
                                                                  cart.items
                                                                      .keys
                                                                      .toList()[
                                                                          cart.items.length -
                                                                              i -
                                                                              1]
                                                                      .toString(),
                                                                  cart.items
                                                                      .values
                                                                      .toList()[
                                                                          cart.items.length -
                                                                              i -
                                                                              1]
                                                                      .name,
                                                                  double.parse(cart
                                                                      .items
                                                                      .values
                                                                      .toList()[
                                                                          cart.items.length -
                                                                              i -
                                                                              1]
                                                                      .rate
                                                                      .toString()),
                                                                  cart.items
                                                                      .values
                                                                      .toList()[
                                                                          cart.items.length -
                                                                              i -
                                                                              1]
                                                                      .storeId,
                                                                );
                                                              },
                                                              child: const Icon(
                                                                Icons
                                                                    .add_circle_outline,
                                                                color: Colors
                                                                    .green,
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                                width: 1)
                                                          ]),
                                                    ),
                                                    SizedBox(
                                                      width: 60,
                                                      child: Text(
                                                        cart.items.values
                                                            .toList()[cart.items
                                                                    .length -
                                                                i -
                                                                1]
                                                            .rate
                                                            .toString(),
                                                        style: const TextStyle(
                                                            color:
                                                                Colors.white),
                                                      ),
                                                    ),
                                                    SizedBox(
                                                      width: 70,
                                                      child: Center(
                                                        child: Text(
                                                          "${cart.items.values.toList()[cart.items.length - i - 1].rate! * cart.items.values.toList()[cart.items.length - i - 1].quantity!}",
                                                          style:
                                                              const TextStyle(
                                                                  color: Colors
                                                                      .white),
                                                        ),
                                                      ),
                                                    ),
                                                    SizedBox(
                                                        width: 20,
                                                        child: cart.items.values
                                                                    .toList()[cart
                                                                            .items
                                                                            .length -
                                                                        i -
                                                                        1]
                                                                    .oldQuantity ==
                                                                0
                                                            ? InkWell(
                                                                onTap: () {
                                                                  Globals.timer
                                                                      ?.cancel();
                                                                  Globals.checkTime(
                                                                      context);

                                                                  final myAudio =
                                                                      MyAudio();
                                                                  myAudio
                                                                      .playSound();
                                                                  cart.removeItem(
                                                                    cart.items
                                                                        .keys
                                                                        .toList()[cart
                                                                            .items
                                                                            .length -
                                                                        i -
                                                                        1],
                                                                  );
                                                                },
                                                                child: const Icon(
                                                                    Icons
                                                                        .delete,
                                                                    color: Colors
                                                                        .red))
                                                            : InkWell(
                                                                onTap: () {
                                                                  Globals.timer
                                                                      ?.cancel();
                                                                  Globals.checkTime(
                                                                      context);

                                                                  final myAudio =
                                                                      MyAudio();
                                                                  myAudio
                                                                      .playSound();
                                                                  cart.items
                                                                      .forEach((key,
                                                                          value) {});
                                                                },
                                                                child: const Icon(
                                                                    Icons.check,
                                                                    color: Colors
                                                                        .green))),
                                                  ]),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    decoration:
                                        BoxDecoration(color: Colors.grey[200]),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 5.0),
                                    child: Column(
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.all(4.0),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceEvenly,
                                            children: [
                                              Column(children: [
                                                const Text(
                                                  'Total Quantity',
                                                  style: TextStyle(
                                                      color: Colors.blueGrey,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                                Text(
                                                  cart.totalItemsCount
                                                      .toString(),
                                                  style: const TextStyle(
                                                      color: Colors.blueGrey,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                )
                                              ]),
                                              Column(children: [
                                                const Text(
                                                  'Gross Amount',
                                                  style: TextStyle(
                                                      color: Colors.blueGrey,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                                Text(
                                                  "Rs.${cart.totalAmount}",
                                                  style: const TextStyle(
                                                      color: Colors.blueGrey,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                )
                                              ]),
                                              Column(children: [
                                                const Text('Discount Amount',
                                                    style: TextStyle(
                                                        color: Colors.blueGrey,
                                                        fontWeight:
                                                            FontWeight.bold)),
                                                Text(
                                                  "Rs.${discount.toString()}",
                                                  style: const TextStyle(
                                                      color: Colors.blueGrey,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                )
                                              ]),
                                              Column(children: [
                                                const Text(
                                                  'No. of Guest',
                                                  style: TextStyle(
                                                      color: Colors.blueGrey,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                                Container(
                                                    decoration: BoxDecoration(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(5),
                                                        color: Colors.white),
                                                    width: 70,
                                                    height: 24,
                                                    child: TextFormField(
                                                      style: const TextStyle(
                                                          color:
                                                              Colors.blueGrey,
                                                          fontWeight:
                                                              FontWeight.bold),
                                                      controller:
                                                          guestController,
                                                      keyboardType:
                                                          TextInputType.number,
                                                      decoration:
                                                          const InputDecoration(
                                                              border:
                                                                  InputBorder
                                                                      .none),
                                                    ))
                                              ]),
                                              Column(children: [
                                                const Text(
                                                  'Net Amount',
                                                  style: TextStyle(
                                                      color: Colors.blueGrey,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                                Text(
                                                  "Rs." +
                                                      (cart.totalAmount -
                                                              (discount))
                                                          .toString(),
                                                  style: const TextStyle(
                                                      color: Colors.blueGrey,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                )
                                              ]),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          color: Colors.grey[200],
                                          child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceEvenly,
                                              children: [
                                                Expanded(
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            6.0),
                                                    child: ElevatedButton(
                                                      style: ElevatedButton
                                                          .styleFrom(
                                                        primary:
                                                            Colors.redAccent,
                                                      ),
                                                      onPressed: () {
                                                        final myAudio =
                                                            MyAudio();

                                                        Globals.timer?.cancel();
                                                        Globals.checkTime(
                                                            context);
                                                        cart.clear();
                                                        Navigator.of(context)
                                                            .pop(true);
                                                        myAudio.playSound();
                                                      },
                                                      child: const Text(
                                                        'Back to POS',
                                                        style: TextStyle(
                                                            color:
                                                                Colors.white),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 200),
                                                Expanded(
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            6.0),
                                                    child: ElevatedButton(
                                                      style: ElevatedButton
                                                          .styleFrom(
                                                        primary: Colors.teal,
                                                      ),
                                                      onPressed:
                                                          _isButtonDisabled == 0
                                                              ? () {
                                                                  Globals.timer
                                                                      ?.cancel();
                                                                  Globals.checkTime(
                                                                      context);
                                                                  final myAudio =
                                                                      MyAudio();
                                                                  myAudio
                                                                      .playSound();

                                                                  var cartItems =
                                                                      [];
                                                                  cart.items.forEach(
                                                                      (key, value) =>
                                                                          {
                                                                            cartItems.add({
                                                                              'product_id': key,
                                                                              'quantity': value.quantity,
                                                                              'rate': value.rate,
                                                                              'amount': value.quantity! * value.rate!,
                                                                              'product_store_id': value.storeId,
                                                                              'plus_quantity': value.plusQuantity,
                                                                              'is_new': value.isNew ?? 0,
                                                                              'order_id': oldOrder['id']
                                                                            })
                                                                          });

                                                                  if (oldOrder[
                                                                              'table_id'] ==
                                                                          null ||
                                                                      widget.data ==
                                                                          null) {
                                                                    toast(
                                                                        'Table or user not selected',
                                                                        Colors
                                                                            .green);
                                                                  } else {
                                                                    bool found =
                                                                        cartItems.any((element) =>
                                                                            element['is_new'] ==
                                                                            1);
                                                                    if (found ==
                                                                        true) {
                                                                      var body = jsonEncode(<
                                                                          String,
                                                                          dynamic>{
                                                                        "total_update":
                                                                            totalUpdate,
                                                                        'order_items':
                                                                            cartItems,
                                                                        'gross_amount': cart
                                                                            .totalAmount
                                                                            .toString(),
                                                                        'net_amount':
                                                                            (cart.totalAmount - discount).toString(),
                                                                        'user_id':
                                                                            widget.data['id'],
                                                                        'store_id':
                                                                            widget.data['store_id'],
                                                                        'no_of_guest':
                                                                            guestController.text,
                                                                        'remark':
                                                                            remarksController.text,
                                                                        'table_id':
                                                                            oldOrder['table_id'],
                                                                      });
                                                                      //print(body);
                                                                      checkout(
                                                                          body:
                                                                              body,
                                                                          cart:
                                                                              cart);
                                                                    } else {
                                                                      toast(
                                                                          "No item added",
                                                                          Colors
                                                                              .yellowAccent);
                                                                    }
                                                                  }
                                                                }
                                                              : () {
                                                                  Globals.timer
                                                                      ?.cancel();
                                                                  Globals.checkTime(
                                                                      context);
                                                                },
                                                      child: Text(
                                                        _isButtonDisabled == 1
                                                            ? "Hold on..."
                                                            : "Update Now",
                                                        style: const TextStyle(
                                                            color:
                                                                Colors.white),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ]),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 4,
                          child: Card(
                            elevation: 5,
                            child: Container(
                              decoration: const BoxDecoration(
                                  border: Border(
                                      top: BorderSide(
                                          color: Colors.blueGrey, width: 5)),
                                  color: Colors.white),
                              child: Column(
                                children: [
                                  Container(
                                    margin: const EdgeInsets.only(top: 6.0),
                                    child: Padding(
                                      padding: const EdgeInsets.all(3.0),
                                      child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          children: [
                                            // Expanded(
                                            //   flex: 2,
                                            //   child: Container(

                                            //     decoration: BoxDecoration(
                                            //         color: Colors.white,
                                            //         border: Border.all(
                                            //             color: Colors.grey[400]),
                                            //         borderRadius:
                                            //             BorderRadius.circular(5)),
                                            //     height: 35,
                                            //     // width:
                                            //     //     MediaQuery.of(context).size.width * 0.2,
                                            //     child: Padding(
                                            //       padding: const EdgeInsets.all(4.0),
                                            //       child: getCategories(categories),
                                            //     ),
                                            //   ),
                                            // ),
                                            Expanded(
                                              child: Container(
                                                decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    border: Border.all(
                                                        color:
                                                            Colors.grey[400]!),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            2)),
                                                height: 35,
                                                // width:
                                                //     MediaQuery.of(context).size.width * 0.15,

                                                child: TextField(
                                                  controller: filterController,
                                                  onChanged:
                                                      onSearchTextChanged,
                                                  //  autocorrect: true,
                                                  decoration:
                                                      const InputDecoration(
                                                          isDense: true,
                                                          contentPadding:
                                                              EdgeInsets.all(
                                                                  6.5),
                                                          hintText:
                                                              'Search Item',
                                                          border:
                                                              InputBorder.none),
                                                ),
                                              ),
                                            ),

                                            const SizedBox(
                                              width: 3.0,
                                            ),
                                            InkWell(
                                              onTap: () {
                                                Globals.timer?.cancel();
                                                Globals.checkTime(context);
                                                filterController.clear();
                                                onSearchTextChanged('');
                                              },
                                              child: Container(
                                                decoration: BoxDecoration(
                                                    color: Colors.teal,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            4)),
                                                child: const Padding(
                                                  padding: EdgeInsets.all(8.0),
                                                  child: Text(
                                                    'All',
                                                    style: TextStyle(
                                                        color: Colors.white),
                                                  ),
                                                ),
                                              ),
                                            )
                                          ]),
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 10,
                                  ),
                                  Expanded(
                                    child: GridView.count(
                                        shrinkWrap: true,
                                        crossAxisCount: 4,
                                        padding: const EdgeInsets.all(4.0),
                                        children: _searchResult.map((product) {
                                          return Padding(
                                            padding: const EdgeInsets.all(2.0),
                                            child: InkWell(
                                              onTap: () {
                                                Globals.timer?.cancel();
                                                Globals.checkTime(context);
                                                showDialog(
                                                    context: context,
                                                    builder:
                                                        (BuildContext context) {
                                                      return ProductDialog(
                                                        categoryId: product.id,
                                                      );
                                                    });
                                              },
                                              child: Container(
                                                decoration: BoxDecoration(
                                                    color: Colors.blueGrey,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10)),
                                                child: Padding(
                                                  padding: const EdgeInsets.all(
                                                      10.0),
                                                  child: Center(
                                                    child: Text(
                                                      product.name.toString(),
                                                      style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 13,
                                                          fontWeight:
                                                              FontWeight.bold),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        }).toList()),
                                  )
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
                ),
              ),
            ));
      }),
    );
  }
}
//   Widget getCategories(List<Category> categories) {
//     return DropdownButton<Category>(
//       icon: Container(
//           margin: EdgeInsets.only(left: 10),
//           alignment: Alignment.topRight,
//           child: Icon(Icons.arrow_drop_down)),
//       underline: Text(''),
//       iconSize: 20,
//       hint: Text("Select Category"),
//       value: selectedCategory,
//       onChanged: (Category val) {
//         setState(() {
//           selectedCategory = val;
//           fetchProductsByCategoryWise(val.id);
//         });
//       },
//       items: categories.map((Category user) {
//         return DropdownMenuItem<Category>(
//           value: user,
//           child: Row(
//             children: <Widget>[
//               Icon(
//                 Icons.restaurant_menu_sharp,
//                 size: 18,
//                 color: Colors.teal,
//               ),
//               SizedBox(
//                 width: 10,
//               ),
//               Text(
//                 user.name,
//                 style: TextStyle(color: Colors.black),
//               ),
//             ],
//           ),
//         );
//       }).toList(),
//     );
//   }

// }
