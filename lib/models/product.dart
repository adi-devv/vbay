import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String? itemID;
  String? status, sellerName, sellerHostel, sellerID, itemURL, college;
  String itemName, category, condition, itemDescription, imagePath;
  int price;
  int? quantity;
  List<String>? reasons;
  DateTime? createdAt, updatedAt;

  Product({
    required this.itemName,
    required this.category,
    required this.condition,
    required this.price,
    required this.itemDescription,
    required this.imagePath,
    required this.sellerName,
    required this.sellerHostel,
    this.quantity,
    this.sellerID,
    this.itemID,
    this.status,
    this.reasons,
    this.createdAt,
    this.updatedAt,
    this.itemURL,
    this.college,
  });

  factory Product.fromMap(
    Map<String, dynamic> data, [
    String? itemID,
    String? sellerName,
    String? sellerHostel,
    String? status,
    String? sellerID,
  ]) {
    var updatedAt = (data['updatedAt'] != null && data['updatedAt'] is Timestamp)
        ? (data['updatedAt'] as Timestamp).toDate()
        : null;
    var createdAt = (data['createdAt'] != null && data['createdAt'] is Timestamp)
        ? (data['createdAt'] as Timestamp).toDate()
        : null;

    return Product(
      itemID: itemID,
      itemName: data['itemName'],
      category: data['category'],
      condition: data['condition'],
      price: data['price'],
      quantity: data['quantity'],
      itemDescription: data['itemDescription'],
      imagePath: data['imagePath'],
      sellerName: data['sellerName'] ?? sellerName,
      sellerHostel: data['sellerHostel'] ?? sellerHostel,
      sellerID: data['sellerID'] ?? sellerID,
      status: data['status'] ?? status,
      updatedAt: updatedAt,
      createdAt: createdAt,
      itemURL: data['itemURL'],
      college: data['college'],
      reasons: data['reasons'] != null ? List<String>.from(data['reasons']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'itemName': itemName,
      'category': category,
      'condition': condition,
      'price': price,
      'quantity': quantity,
      'itemDescription': itemDescription,
      'imagePath': imagePath,
      'sellerName': sellerName,
      'sellerHostel': sellerHostel,
      'sellerID': sellerID,
      'itemURL': itemURL,
      'college': college,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
