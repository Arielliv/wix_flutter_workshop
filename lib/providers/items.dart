import 'dart:convert';
import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../providers/item.dart';
import 'package:path/path.dart' as path;

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
        final List<Item> loadedItems = [];
        for (var entry in extractedData.entries) {
          var file = await downloadImage(entry.value['image']);
          Future.delayed(const Duration(milliseconds: 20), () => "20");
          loadedItems.add(Item(
            id: entry.key,
            title: entry.value['title'],
            description: entry.value['description'],
            price: entry.value['price'],
            isFavorite: false,
            image: file,
          ));
        }
        _items = loadedItems;

        notifyListeners();
      }
    } catch (error) {
      throw error;
    }
  }

  Future downloadImage(String imageName) async {
    StorageReference firebaseStorageRef =
        FirebaseStorage.instance.ref().child(imageName);
    String downloadUrl = await firebaseStorageRef.getDownloadURL();
    http.Client client = new http.Client();
    var req = await client.get(Uri.parse(downloadUrl));
    var bytes = req.bodyBytes;
    String dir = (await getApplicationDocumentsDirectory()).path;
    File file = new File('$dir/$imageName');
    await file.writeAsBytes(bytes);
    await file.create();
    return file;
  }

  Future<void> addItem(Item item) async {
    final url = '$baseUrl/items.json?auth=$authToken';
    try {
      print(path.basename(item.image.path));
      print(path.extension(item.image.path));
      final response = await http.post(url,
          body: json.encode({
            'title': item.title,
            'description': item.description,
            'price': item.price,
            'creatorId': userId,
            'image': path.basename(item.image.path)
          }));

      await uploadPic(item.image);

      final newItem = Item(
          title: item.title,
          description: item.description,
          price: item.price,
          id: json.decode(response.body)['name'],
          image: item.image);

      _items.add(newItem);
    } catch (error) {
      throw error;
    }
  }

Future<void> uploadPic(File image) async {
    String fileName = path.basename(image.path);
    StorageReference firebaseStorageRef =
        FirebaseStorage.instance.ref().child(fileName);
    StorageUploadTask uploadTask = firebaseStorageRef.putFile(image);
    uploadTask.onComplete;
  }
}
