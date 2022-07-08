import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:restro_simplify/controller/CartController.dart';
import 'package:restro_simplify/controller/TimeController.dart';
import 'package:restro_simplify/controller/audio_controller.dart';
import 'package:restro_simplify/models/Product.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class ProductDialog extends StatefulWidget {
  final String categoryId;
  const ProductDialog({Key? key, required this.categoryId}) : super(key: key);

  @override
  State<ProductDialog> createState() => _ProductDialogState();
}

class _ProductDialogState extends State<ProductDialog> {
  List<Product> prouctList = [];
  List<Product> searchProductList = [];
  final TextEditingController filterController = TextEditingController();
  @override
  void initState() {
    super.initState();
    fetchProduct();
  }

  void fetchProduct() async {
    try {
      List<Product> cats;
      final url = Uri.parse(
          'http://192.168.1.1/restroms/api/products/getProductByCategory');
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final floorId = prefs.getString('floorId');
      Map<String, String> header = {
        'Accept': 'application/json',
      };
      var body = {
        "floor_id": floorId,
        "category_id": widget.categoryId,
      };
      final res = await http.post(url, headers: header, body: body);

      if (res.statusCode == 200) {
        var jsonData = jsonDecode(res.body);
        cats = [];
        for (var data in jsonData) {
          cats.add(Product.fromJson(data));
        }
        if (mounted) {
          setState(() {
            prouctList = cats;
            searchProductList = prouctList;
          });
        }
      }
    } catch (error) {
      if (kDebugMode) {
        print(error);
      }
    }
  }

  void onSearchTextChanged(String text) {
    Globals.timer?.cancel();
    Globals.checkTime(context);

    List<Product> myList = text.isEmpty
        ? prouctList
        : prouctList
            .where((p) => p.name.toLowerCase().contains(text.toLowerCase()))
            .toList();

    setState(() {
      searchProductList = myList;
    });
  }

  @override
  Widget build(BuildContext context) {
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
      child: Dialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.0)), //this right here
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.grey[400]!),
                            borderRadius: BorderRadius.circular(2)),
                        height: 35,
                        // width:
                        //     MediaQuery.of(context).size.width * 0.15,

                        child: TextField(
                          controller: filterController,
                          onChanged: onSearchTextChanged,
                          //  autocorrect: true,
                          decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.all(6.5),
                              hintText: 'Search Item',
                              border: InputBorder.none),
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: 8.0,
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
                            borderRadius: BorderRadius.circular(4)),
                        child: const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text(
                            'All',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: 20.0,
                    ),
                    IconButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.close))
                  ],
                ),
                Expanded(
                  child: prouctList.isEmpty
                      ? const Center(
                          child: Text('No Item Avaible'),
                        )
                      : GridView.count(
                          crossAxisCount: 8,
                          padding: const EdgeInsets.all(4.0),
                          children: searchProductList.map((product) {
                            return Padding(
                              padding: const EdgeInsets.all(2.0),
                              child: InkWell(
                                onTap: () {
                                  Globals.timer?.cancel();
                                  Globals.checkTime(context);

                                  final myAudio = MyAudio();
                                  myAudio.playSound();

                                  final cart = Provider.of<CartController>(
                                      context,
                                      listen: false);
                                  cart.addItem(
                                      product.id.toString(),
                                      product.name.toString(),
                                      double.parse(product.price),
                                      int.parse(product.storeId));
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                      color: Colors.blueGrey,
                                      borderRadius:
                                          BorderRadius.circular(10.0)),
                                  child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Card(
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(50)),
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(50),
                                            child: product.image != null
                                                ? Image.network(product.image!,
                                                    height: 65,
                                                    width: 65, errorBuilder:
                                                        (context, x, s) {
                                                    return Container(
                                                      height: 65,
                                                      width: 65,
                                                      padding:
                                                          const EdgeInsets.all(
                                                              8),
                                                      decoration: BoxDecoration(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(50),
                                                          border: Border.all(
                                                              color:
                                                                  Colors.white,
                                                              width: 2)),
                                                      child: const InkWell(
                                                        child: Icon(
                                                          Icons.add,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    );
                                                  })
                                                : Image.asset(
                                                    'assets/logo.png',
                                                    height: 65,
                                                    width: 65,
                                                  ),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(1.0),
                                          child: Text(
                                            product.name.toString(),
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(1.0),
                                          child: Text(
                                            'Rs.' + product.price.toString(),
                                            style: const TextStyle(
                                                color: Colors.yellow,
                                                fontSize: 12),
                                          ),
                                        )
                                      ]),
                                ),
                              ),
                            );
                          }).toList()),
                ),
              ],
            ),
          )),
    );
  }
}
