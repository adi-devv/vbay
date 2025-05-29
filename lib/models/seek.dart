import 'package:cloud_firestore/cloud_firestore.dart';

class Seek {
  final String itemID;
  String seekerName, seekerHostel, itemName;
  String? seekerID, status, college;
  DateTime updatedAt;
  bool isUrgent;
  List<String>? reasons;

  Seek({
    required this.itemName,
    required this.seekerName,
    required this.seekerHostel,
    required this.itemID,
    required this.isUrgent,
    required this.updatedAt,
    this.status,
    this.seekerID,
    this.reasons,
    this.college,
  });

  factory Seek.fromMap(
    Map<String, dynamic> data, [
    String? itemID,
    String? seekerName,
    String? seekerHostel,
    String? seekerID,
  ]) {
    var updatedAt = (data['updatedAt'] is Timestamp) ? (data['updatedAt'] as Timestamp).toDate() : DateTime.now();
    return Seek(
      itemID: itemID!,
      itemName: data['itemName'],
      seekerName: data['seekerName'] ?? seekerName,
      seekerHostel: data['seekerHostel'] ?? seekerHostel,
      isUrgent: data['isUrgent'],
      status: data['status'],
      seekerID: data['seekerID'] ?? seekerID,
      updatedAt: updatedAt,
      reasons: data['reasons'] != null ? List<String>.from(data['reasons']) : null,
      college: data['college'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'itemID': itemID,
      'itemName': itemName,
      'seekerName': seekerName,
      'seekerID': seekerID,
      'seekerHostel': seekerHostel,
      'isUrgent': isUrgent,
      'updatedAt': FieldValue.serverTimestamp(),
      'reasons': reasons,
      'college': college,
    };
  }
}
