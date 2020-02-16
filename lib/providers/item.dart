import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class Item with ChangeNotifier {
  final String id;
  final String title;
  final String description;
  final double price;
  final String imagePath;
  bool isFavorite;

  Item({
    @required this.id,
    @required this.title,
    @required this.description,
    @required this.price,
    this.imagePath,
    this.isFavorite = false,
  });
}
