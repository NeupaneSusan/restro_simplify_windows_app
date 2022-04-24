// ignore_for_file: file_names

class CartItem {
  String? id;
  String? name;
  double? rate;
  int? quantity;
  int? storeId;
  int plusQuantity;
  int? isNew;
  int? oldQuantity;
  CartItem({this.id, this.name, this.rate, this.quantity,this.storeId,this.isNew,this.plusQuantity = 0,this.oldQuantity, int? isedit});
}
