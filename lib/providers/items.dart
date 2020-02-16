import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import '../providers/item.dart';

class Items with ChangeNotifier {
  final String baseUrl = 'https://flutter-workshop-eef86.firebaseio.com';
  List<Item> _items = [];

  final String authToken;
  final String userId;

  Items(this.authToken, this.userId, this._items);

  List<Item> get items {
    return [..._items];
  }

  Item findById(String id) {
    return _items.firstWhere((item) => item.id == id);
  }

  Future<void> fetchAndSetItems([bool filterByUser = false]) async {
    final filterUrl =
        filterByUser ? 'orderBy="creatorId"&equalTo="$userId"' : '';
    var url = '$baseUrl/items.json?auth=$authToken&$filterUrl';
    print(authToken);
    try {
      final response = await http.get(url);
      final extractedData = json.decode(response.body) as Map<String, dynamic>;
      if (extractedData == null) {
        return;
      } else {
        final url = '$baseUrl/userFavorites/$userId.json?auth=$authToken';
        final favoriteResponse = await http.get(url);
        final favoriteData = json.decode(favoriteResponse.body);
        final List<Item> loadedItems = [];
        extractedData.forEach((itemId, itemData) {
          loadedItems.add(Item(
            id: itemId,
            title: itemData['title'],
            description: itemData['description'],
            price: itemData['price'],
            isFavorite:
                favoriteData == null ? false : favoriteData[itemId] ?? false,
            imagePath: itemData['imagePath'],
          ));
        });
        _items = loadedItems;

        notifyListeners();
      }
    } catch (error) {
      throw error;
    }
  }
}
