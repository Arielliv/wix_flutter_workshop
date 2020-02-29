import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/items.dart';

class ItemDetailScreen extends StatelessWidget {
  static const routeName = '/item-detail';

  @override
  Widget build(BuildContext context) {
    final itemId = ModalRoute.of(context).settings.arguments as String;
    final loadedItem = Provider.of<Items>(
      context,
      listen: false,
    ).findById(itemId);

    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(loadedItem.title),
              background: Hero(
                tag: loadedItem.id,
                child: Image.file(
                  File(
                    loadedItem.image.path,
                  ),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate(
              [
                SizedBox(
                  height: 10,
                ),
                Text(
                  '\$${loadedItem.price}',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 20,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(
                  height: 10,
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  width: double.infinity,
                  child: Text(
                    loadedItem.description,
                    textAlign: TextAlign.center,
                    softWrap: true,
                  ),
                ),
                SizedBox(
                  height: 800,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
