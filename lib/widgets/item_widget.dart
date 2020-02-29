import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wix_flutter_workshop/screens/item_detail_screen.dart';
import '../providers/item.dart';

class ItemWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final item = Provider.of<Item>(context, listen: false);
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: GridTile(
        child: GestureDetector(
          onTap: () {
            Navigator.of(context).pushNamed(
              ItemDetailScreen.routeName,
              arguments: item.id,
            );
          },
          child: Hero(
            tag: item.id,
            child: FadeInImage(
              placeholder: AssetImage('assets/images/wix-logo.jpg'),
              image: FileImage(item.image),
              fit: BoxFit.cover,
            ),
          ),
        ),
        footer: GridTileBar(
          backgroundColor: Colors.black87,
          title: Text(
            item.title,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
