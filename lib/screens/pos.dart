// ignore_for_file: prefer_typing_uninitialized_variables

import 'package:flutter/material.dart';
import 'package:connectivity/connectivity.dart';
import 'package:flutter/services.dart';
import 'package:flutter_beep/flutter_beep.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';

import 'package:provider/provider.dart';
import 'package:restro_simplify/controller/CartController.dart';
import 'package:restro_simplify/controller/TimeController.dart';
import 'package:restro_simplify/dialog/product_dialog.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/Category.dart';
import '../models/Tables.dart';
import '../models/Product.dart';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;

class PosPage extends StatefulWidget {
   PosPage({Key? key, this.data,required this.selectedTable}) : super(key: key);

  final data;
   Tables selectedTable;

  @override
  _PosPageState createState() => _PosPageState();
}

class _PosPageState extends State<PosPage> {
  TextEditingController guestController = TextEditingController();
  TextEditingController remarksController = TextEditingController();
  TextEditingController filterController = TextEditingController();

  List<Category> categories = <Category>[];
  List<Tables> tables = <Tables>[];
  List<Product> products = <Product>[];
  List<Category> _searchResult = [];

  Category? selectedCategory;
   Tables? selectedTable;

  int? _isButtonDisabled;

  final url = "http://192.168.1.1/restroms/api";
 
  final imgUrl = 'http://192.168.1.1/restroms/';

//fetch categories
  Future<String> fetchCategories() async {
    var res = await http.get(Uri.parse(url + '/categories'));
    if (res.statusCode == 200) {
      var jsonData = jsonDecode(res.body);

      List<Category> cats = [];
      for (var data in jsonData) {
        cats.add(Category.fromJson(data));
      }
      if (mounted) {
        setState(() {
          categories = cats;
          _searchResult = categories;
        });
      }

      return 'success';
    } else {
      throw "Can't get categories.";
    }
  }

//fetch tables
  Future<String> fetchTables() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var floorId = prefs.getString('floorId');

    var res = await http.get(Uri.parse(url + '/tables/$floorId'));
    if (res.statusCode == 200) {
      var jsonData = jsonDecode(res.body);
      List<Tables> cats = [];
      for (var data in jsonData['data']) {
        cats.add(Tables.fromJson(data));
      }
      if (mounted) {
        setState(() {
          tables = cats;
        });
      }

      return 'success';
    } else {
      throw "Can't get tables.";
    }
  }

  
  
  void toast(message, color) {
  showToast(
     message,
    context:context,
    duration: const Duration(seconds: 2),
  position: StyledToastPosition.center,  
      
      
        backgroundColor: color);
  }

 
  // post address
  Future<bool> checkout({var body, cart}) async {
    Map<String, String> header = {
      'Content-type': 'application/json',
      'Accept': 'application/json',
    };

    var res = await http.post(
      Uri.parse(url + '/tableOrders'),
      headers: header,
      body: body,
    );
    if (res.statusCode == 200) {
      toast("Order Success", Colors.green);
      selectedTable = null;
      guestController.text = 0.toString();
      setState(() {
        _isButtonDisabled = 0;
      });
      cart.clear();
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
                      selectedTable = null;
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
      setState(() {
        _isButtonDisabled = 0;
      });
      var jsonData = json.decode(res.body);
      toast(jsonData['message'].toString(), Colors.red);

      return false;
    }
  }

  // check internet
  internetChecker() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.mobile ||
        connectivityResult == ConnectivityResult.wifi) {
     PosPage(selectedTable: widget.selectedTable,);
    } else {
      const Scaffold(
        body: Center(
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
    super.initState();
    fetchCategories();
    fetchTables();
    _isButtonDisabled = 0;
    selectedTable = widget.selectedTable;
  }

  @override
  Widget build(BuildContext context) {
    // Set landscape orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    return Consumer<CartController>(builder: (context, cart, child) {
      return Scaffold(
        body:   SingleChildScrollView(
          child: SizedBox(
             width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height*0.92,
            child: GestureDetector(
              onTap: () {
                Globals.timer?.cancel();
                Globals.checkTime(context);
                FocusScope.of(context).requestFocus(FocusNode());
              },
              child: SafeArea(
                  child: Container(
                margin: const EdgeInsets.only(top: 5, left: 5, right: 5, bottom: 0),
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
                                  top: BorderSide(color: Colors.teal, width: 5))),
                          child: Column(
                            children: [
                              Row(children: [
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Row(
                                    children: [
                                     
                                      InkWell(
                                        onTap: () async {
                                          Globals.timer?.cancel();
                                          Globals.checkTime(context);
                                          await fetchTables();
                                          getTables(context);
                                        },
                                        child: Container(
                                            width: 100,
                                            height: 35,
                                            decoration: BoxDecoration(
                                                color: Colors.teal,
                                                border:
                                                    Border.all(color: Colors.grey)),
                                            child: Padding(
                                              padding: const EdgeInsets.all(8.0),
                                              child: Center(
                                                  child: Text(
                                                selectedTable != null
                                                    ? selectedTable!.name
                                                    : 'Select Table',
                                                style: const TextStyle(
                                                    color: Colors.white),
                                              )),
                                            )),
                                      ),
                                      const SizedBox(width: 10),
                                      Container(
                                        height: 35,
                                        decoration: BoxDecoration(
                                            border: Border.all(color: Colors.grey)),
                                        child: const Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: Icon(
                                            Icons.edit,
                                            size: 16,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        width: MediaQuery.of(context).size.width *
                                            0.418,
                                        height: 35,
                                        decoration: BoxDecoration(
                                            color: Colors.white30,
                                            border: Border.all(color: Colors.grey)),
                                        child: TextField(
                                          controller: remarksController,
                                          decoration: const InputDecoration(
                                              isDense: true,
                                              contentPadding: EdgeInsets.all(6.5),
                                              hintText: 'Remarks',
                                              border: InputBorder.none),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ]),
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
                                            style: TextStyle(color: Colors.white),
                                          ),
                                        ),
                                        SizedBox(
                                          width: 100,
                                          child: Center(
                                            child: Text(
                                              'Quantity',
                                              style: TextStyle(color: Colors.white),
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                          width: 60,
                                          child: Text(
                                            'Price',
                                            style: TextStyle(color: Colors.white),
                                          ),
                                        ),
                                        SizedBox(
                                          width: 70,
                                          child: Center(
                                            child: Text(
                                              'Amount',
                                              style: TextStyle(color: Colors.white),
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                          width: 20,
                                          child: Text(
                                            'X',
                                            style: TextStyle(color: Colors.white),
                                          ),
                                        ),
                                      ]),
                                ),
                              ),
                              
                              
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      border: Border.all(color: Colors.teal[100]!)),
                                 
                                     
                                       child:  Padding(
                                          padding: const EdgeInsets.all(1.0),
                                          child: ListView.builder(
                                            scrollDirection: Axis.vertical,
                                            itemCount: cart.items.length,
                                            itemBuilder:
                                                (BuildContext context, int i) => Card(
                                              elevation: 1,
                                              color: i % 2 == 0
                                                  ? Colors.blueGrey[200]
                                                  : Colors.blueGrey[300],
                                              child: Padding(
                                                padding: const EdgeInsets.all(1.0),
                                                child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.spaceEvenly,
                                                    children: [
                                                      SizedBox(
                                                        width: 130,
                                                        child: Text(
                                                          cart.items.values
                                                              .toList()[
                                                                  cart.items.length -
                                                                      i -
                                                                      1]
                                                              .name!,
                                                          style: const TextStyle(
                                                              color: Colors.white),
                                                        ),
                                                      ),
                                                      Container(
                                                        decoration: BoxDecoration(
                                                            color: Colors.white38,
                                                            borderRadius:
                                                                BorderRadius.circular(
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
                                                                    InkWell(
                                                                  onTap: () {
                                                                    Globals.timer
                                                                        ?.cancel();
                                                                    Globals.checkTime(
                                                                        context);
                                                                    cart.removeSingleItem(cart
                                                                        .items.keys
                                                                        .toList()[cart
                                                                            .items
                                                                            .length -
                                                                        i -
                                                                        1]);
                                                                
                                                                    FlutterBeep
                                                                        .beep();
                                                                  },
                                                                  child: const Icon(
                                                                    Icons
                                                                        .remove_circle_outline,
                                                                    color: Colors.red,
                                                                  ),
                                                                ),
                                                              ),
                                                              Text(cart.items.values
                                                                  .toList()[cart.items
                                                                          .length -
                                                                      i -
                                                                      1]
                                                                  .quantity
                                                                  .toString()),
                                                              InkWell(
                                                                enableFeedback: true,
                                                                onTap: () {
                                                                  Globals.timer
                                                                      ?.cancel();
                                                                  Globals.checkTime(
                                                                      context);
                                                                  cart.addItem(
                                                                      cart.items.keys
                                                                          .toList()[cart
                                                                                  .items
                                                                                  .length -
                                                                              i -
                                                                              1]
                                                                          .toString(),
                                                                      cart.items.values
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
                                                                      cart.items.values
                                                                          .toList()[
                                                                              cart.items.length -
                                                                                  i -
                                                                                  1]
                                                                          .storeId);
                                                                 
                                                                  FlutterBeep.beep();
                                                                },
                                                                child: const Icon(
                                                                  Icons.add_circle_outline,
                                                                  color: Colors.green,
                                                                ),
                                                              ),
                                                              const SizedBox(width: 1)
                                                            ]),
                                                      ),
                                                      SizedBox(
                                                        width: 60,
                                                        child: Text(
                                                          cart.items.values
                                                              .toList()[
                                                                  cart.items.length -
                                                                      i -
                                                                      1]
                                                              .rate
                                                              .toString(),
                                                          style: const TextStyle(
                                                              color: Colors.white),
                                                        ),
                                                      ),
                                                      SizedBox(
                                                        width: 70,
                                                        child: Center(
                                                          child: Text(
                                                            "${cart.items.values.toList()[cart.items.length - i - 1].rate! * cart.items.values.toList()[cart.items.length - i - 1].quantity!}",
                                                            style: const TextStyle(
                                                                color: Colors.white),
                                                          ),
                                                        ),
                                                      ),
                                                      SizedBox(
                                                          width: 20,
                                                          child: InkWell(
                                                              onTap: () {
                                                                Globals.timer
                                                                    ?.cancel();
                                                                Globals.checkTime(
                                                                    context);
                                                                cart.removeItem(
                                                                  cart.items.keys
                                                                      .toList()[cart
                                                                          .items
                                                                          .length -
                                                                      i -
                                                                      1],
                                                                );
                                                               
                                                                FlutterBeep.beep();
                                                              },
                                                              child: const Icon(
                                                                  Icons.delete,
                                                                  color:
                                                                      Colors.red))),
                                                    ]),
                                              ),
                                            ),
                                          ),
                                        ),
                                      
                                    
                                
                                ),
                              ),
                              
                            Container(
                                decoration: BoxDecoration(color: Colors.grey[200]),
                                padding: EdgeInsets.symmetric(vertical: 5.0),
                                child: Column(children: [
                                 Padding(
                                    padding: const EdgeInsets.all(1.0),
                                    child: 
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        Column(children: [
                                          const Text(
                                            'Total Quantity',
                                            style: TextStyle(
                                                color: Colors.blueGrey,
                                                fontWeight: FontWeight.bold),
                                          ),
                                          Text(
                                            cart.totalItemsCount.toString(),
                                            style: const TextStyle(
                                                color: Colors.blueGrey,
                                                fontWeight: FontWeight.bold),
                                          )
                                        ]),
                                        Column(children: [
                                          const Text(
                                            'Gross Amount',
                                            style: TextStyle(
                                                color: Colors.blueGrey,
                                                fontWeight: FontWeight.bold),
                                          ),
                                          Text(
                                            "Rs.${cart.totalAmount}",
                                            style: const TextStyle(
                                                color: Colors.blueGrey,
                                                fontWeight: FontWeight.bold),
                                          )
                                        ]),
                                        Column(children: [
                                          const Text(
                                            'No. of Guest',
                                            style: TextStyle(
                                                color: Colors.blueGrey,
                                                fontWeight: FontWeight.bold),
                                          ),
                                          Container(
                                              decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(5),
                                                  color: Colors.white),
                                              width: 70,
                                              height: 20,
                                              child: TextFormField(
                                                style: const TextStyle(
                                                    color: Colors.blueGrey,
                                                    fontWeight: FontWeight.bold),
                                                controller: guestController,
                                                keyboardType: TextInputType.number,
                                                decoration: const InputDecoration(
                                                    isDense: true,
                                                    contentPadding: EdgeInsets.all(2),
                                                    border: InputBorder.none),
                                              ))
                                        ]),
                                        Column(children: [
                                          const Text(
                                            'Net Amount',
                                            style: TextStyle(
                                                color: Colors.blueGrey,
                                                fontWeight: FontWeight.bold),
                                          ),
                                          Text(
                                            "Rs.${cart.totalAmount}",
                                            style: const TextStyle(
                                                color: Colors.blueGrey,
                                                fontWeight: FontWeight.bold),
                                          )
                                        ]),
                                      ],
                                    ),
                                  ),
                                
                                  SizedBox(height: 5.0,),                  
                                  Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                                left: 6.0, bottom: 0.0),
                                            child: ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                
                                                primary: Colors.redAccent,
                                              ),
                                              onPressed:  _isButtonDisabled == 0 ? () {
                                                Globals.timer?.cancel();
                                                Globals.checkTime(context);
                                                cart.clear();
                                                selectedTable = null;
                                                guestController.text = '';
                                                remarksController.text = '';
                                                setState(() {
                                                  _isButtonDisabled = 0;
                                                 
                                                  FlutterBeep.beep();
                                                });
                                              } :(){
                                                Globals.timer?.cancel();
                                                Globals.checkTime(context);
                                              },
                                              child: const Padding(
                                                padding:  EdgeInsets.all(8.0),
                                                child:  Text(
                                                  'Reset POS',
                                                  style: TextStyle(color: Colors.white),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 200),
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                                right: 6.0, bottom: 0.0),
                                            child: ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                primary: Colors.teal,
                                              ),
                                              onPressed: _isButtonDisabled == 0
                                                  ? () {
                                                      Globals.timer?.cancel();
                                                      Globals.checkTime(context);
                                                     
                                                      FlutterBeep.beep();
                                
                                                      var cartItems = [];
                                                      cart.items
                                                          .forEach((key, value) => {
                                                                cartItems.add({
                                                                  'product_id': key,
                                                                  'quantity':
                                                                      value.quantity,
                                                                  'rate': value.rate,
                                                                  'amount': value
                                                                          .quantity! *
                                                                      value.rate!,
                                                                  'product_store_id':
                                                                      value.storeId,
                                                                })
                                                              });
                                
                                                      // print(widget.data);
                                                      if (cartItems.isEmpty) {
                                                        toast(
                                                            'Select at leact one item',
                                                            Colors.orange);
                                                      }
                                                      if (selectedTable == null ||
                                                          widget.data == null) {
                                                        getTables(context);
                                                      }
                                
                                                      if (selectedTable != null &&
                                                          widget.data != null &&
                                                          cartItems.isNotEmpty) {
                                                        var body = jsonEncode(<String,
                                                            dynamic>{
                                                          'order_items': cartItems,
                                                          'gross_amount': cart
                                                              .totalAmount
                                                              .toString(),
                                                          'net_amount': cart
                                                              .totalAmount
                                                              .toString(),
                                                          'user_id':
                                                              widget.data['id'],
                                                          'store_id':
                                                              widget.data['store_id'],
                                                          'no_of_guest':
                                                              guestController.text,
                                                          'remark':
                                                              remarksController.text,
                                                          'table_id':
                                                              selectedTable!.id
                                                        });
                                                        checkout(
                                                            body: body, cart: cart);
                                                        remarksController.clear();
                                                        setState(() {
                                                          _isButtonDisabled = 1;
                                                        });
                                                      }
                                                    }
                                                  : () {
                                                      Globals.timer?.cancel();
                                                      Globals.checkTime(context);
                                                    },
                                              child: Padding(
                                                padding: const EdgeInsets.all(8.0),
                                                child: Text(
                                                  _isButtonDisabled == 1
                                                      ? "Hold on..."
                                                      : "Order Now",
                                                  style: const TextStyle(
                                                      color: Colors.white),
                                                ),
                                              ),
                                            ),
                                          ),
                                        )
                                      ]),
                                                    
                                                      
                                ],),
                              )
                              
                             
                            
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
                                  top:
                                      BorderSide(color: Colors.blueGrey, width: 5)),
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
                                                    color: Colors.grey[400]!),
                                                borderRadius:
                                                    BorderRadius.circular(2)),
                                            height: 35,
                                            // width:
                                            //     MediaQuery.of(context).size.width * 0.15,
                          
                                            child: TextField(
                                              controller: filterController,
                                              onChanged: onSearchTextChanged,
                                              //  autocorrect: true,
                                              decoration: const InputDecoration(
                                                  isDense: true,
                                                  contentPadding:
                                                      EdgeInsets.all(6.5),
                                                  hintText: 'Search Item',
                                                  border: InputBorder.none),
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
                                                    BorderRadius.circular(4)),
                                            child: const Padding(
                                              padding: EdgeInsets.all(8.0),
                                              child: Text(
                                                'All',
                                                style:
                                                    TextStyle(color: Colors.white),
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
                                                builder: (BuildContext context) {
                                                  return ProductDialog(
                                                    categoryId: product.id,
                                                  );
                                                });
                                          },
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.blueGrey,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets.all(10.0),
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
        ),
      );
    });
  }

  // Widget getCategories(List<Category> categories) {
  //   return DropdownButton<Category>(
  //     icon: Container(
  //         margin: EdgeInsets.only(left: 10,),
  //         alignment: Alignment.topRight,
  //         child: Icon(Icons.arrow_drop_down)),
  //     underline: Text(''),
  //     iconSize: 20,
  //     hint: Text("Select Category"),
  //     value: selectedCategory,
  //     onChanged: (Category val) {
  //       setState(() {
  //         selectedCategory = val;
  //         fetchProductsByCategoryWise(val.id);
  //       });
  //     },
  //     items: categories.map((Category user) {
  //       return DropdownMenuItem<Category>(
  //         value: user,
  //         child: Row(
  //           children: <Widget>[
  //             Icon(
  //               Icons.restaurant_menu_sharp,
  //               size: 18,
  //               color: Colors.teal,
  //             ),
  //             SizedBox(
  //               width: 10,
  //             ),
  //             Text(
  //               user.name,
  //               style: TextStyle(color: Colors.black),
  //             ),
  //           ],
  //         ),
  //       );
  //     }).toList(),
  //   );
  // }

  void getTables(BuildContext context) {
    showModalBottomSheet(
        context: context,
        builder: (_) {
          return SizedBox(
              height: MediaQuery.of(context).size.height * 0.75,
              width: MediaQuery.of(context).size.height * 0.65,
              child: 
              tables.isNotEmpty
                  ? GridView.count(
                      crossAxisCount: 10,
                      padding: const EdgeInsets.all(4.0),
                      children: tables.map((table) {
                        return Padding(
                          padding: const EdgeInsets.all(2.0),
                          child: InkWell(
                            onTap: () {
                              Globals.timer?.cancel();
                              Globals.checkTime(context);
                              FlutterBeep.beep();
                              setState(() {
                                selectedTable = table;
                                guestController.text = selectedTable!.capacity;
                              });
                              Navigator.pop(context);
                            },
                            child: Container(
                              decoration: const BoxDecoration(
                                  color: Colors.blueGrey,
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(10))),
                              child: Column(children: [
                                const SizedBox(height: 10),
                                const Padding(
                                    padding: EdgeInsets.all(6.0),
                                    child: Icon(
                                      Icons.table_bar,
                                      color: Colors.white,
                                    )),
                                Padding(
                                  padding: const EdgeInsets.all(1.0),
                                  child: Text(
                                    table.name.toString(),
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ]),
                            ),
                          ),
                        );
                      }).toList())
                  
                  
                  : const Center(child: CircularProgressIndicator()));
        });
  }
}
