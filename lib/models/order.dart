class Order {
  int? num;
  String? role;
  String? productName;
  int? price;
  bool? isPaid;
  DateTime? paidAt;
  DateTime? createdAt;

  Order(this.num, this.role, this.productName, this.price, this.isPaid,
      this.paidAt, this.createdAt);
}
