import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wix_flutter_workshop/screens/add_item_screen.dart';
import 'package:wix_flutter_workshop/widgets/app_drawer.dart';
import '../widgets/items_grid.dart';

import '../providers/items.dart';

class ItemsOverviewScreen extends StatefulWidget {
  @override
  _ProductsOverviewScreenState createState() => _ProductsOverviewScreenState();
}

class _ProductsOverviewScreenState extends State<ItemsOverviewScreen> {
  var _isInit = false;
  var _isLoading = false;

  @override
  void didChangeDependencies() {
    if (!_isInit) {
      _isLoading = true;
      Provider.of<Items>(context).fetchAndSetItems().then((_) {
        setState(() {
          _isLoading = false;
        });
      });
    }

    _isInit = true;
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Flutter Workshop'),
      ),
      drawer: AppDrawer(),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(),
            )
          : ItemsGrid(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).pushNamed(AddItemScreen.routeName);
        },
        tooltip: 'Add Item',
        child: const Icon(Icons.add),
      ),
    );
  }
}
