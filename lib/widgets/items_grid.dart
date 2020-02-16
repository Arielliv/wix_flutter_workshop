import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../screens/items_overview_screen.dart';
import '../widgets/item_widget.dart';

import '../providers/items.dart';

class ItemsGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final items = Provider.of<Items>(context).items;
    
    return GridView.builder(
      padding: const EdgeInsets.all(10.0),
      itemCount: items.length,
      itemBuilder: (ctx, i) => ChangeNotifierProvider.value(
        value: items[i],
        child: Container(
          child: ItemWidget(),
        ),
      ),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 3 / 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
    );
  }
}
