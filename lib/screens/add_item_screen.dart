import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wix_flutter_workshop/providers/item.dart';
import 'package:wix_flutter_workshop/providers/items.dart';
import 'package:wix_flutter_workshop/widgets/inputs/image_input.dart';

class AddItemScreen extends StatefulWidget {
  static const routeName = '/add-item';

  @override
  _AddItemScreenState createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _form = GlobalKey<FormState>();
  final _descriptionFocusNode = FocusNode();

  final _priceFocusNode = FocusNode();
  File _pickedImage;

  void _selectImage(File pickedImage) {
    _pickedImage = pickedImage;
  }

  Future<void> _saveForm() async {
    final isValid = _form.currentState.validate();
    if (!isValid) {
      return;
    }
    _form.currentState.save();
    setState(() {
      _isLoading = true;
    });
    try {
      await Provider.of<Items>(context, listen: false).addItem(_addItem);
    } catch (error) {
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('An error occurred'),
          content: Text(error.toString()), //some thing went wrong
          actions: <Widget>[
            FlatButton(
              child: Text('Okay'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            )
          ],
        ),
      );
    }

    setState(() {
      _isLoading = false;
    });
    Navigator.of(context).pop();
  }

  var _addItem = Item(
    id: null,
    title: '',
    price: 0,
    description: '',
    image: null,
  );

  var _initValues = {
    'title': '',
    'description': '',
    'price': '',
    'image': '',
  };

  @override
  void dispose() {
    _priceFocusNode.dispose();
    _descriptionFocusNode.dispose();
    super.dispose();
  }

  var _isInit = true;
  var _isLoading = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add New Item'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _saveForm,
          )
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _form,
                child: ListView(
                  children: <Widget>[
                    TextFormField(
                      initialValue: _initValues['title'],
                      decoration: InputDecoration(labelText: 'Title'),
                      textInputAction: TextInputAction.next,
                      onSaved: (value) => _addItem = Item(
                        title: value,
                        id: _addItem.id,
                        isFavorite: _addItem.isFavorite,
                        price: _addItem.price,
                        description: _addItem.description,
                        image: _pickedImage != null ? _pickedImage : _addItem,
                      ),
                      validator: (value) {
                        if (value.isEmpty) {
                          return 'Please provide a value';
                        }
                        return null;
                      },
                      onFieldSubmitted: (_) =>
                          FocusScope.of(context).requestFocus(_priceFocusNode),
                    ),
                    TextFormField(
                      initialValue: _initValues['price'],
                      decoration: InputDecoration(labelText: 'Price'),
                      textInputAction: TextInputAction.next,
                      keyboardType: TextInputType.number,
                      focusNode: _priceFocusNode,
                      onSaved: (value) => _addItem = Item(
                        title: _addItem.title,
                        id: _addItem.id,
                        isFavorite: _addItem.isFavorite,
                        price: double.parse(value),
                        description: _addItem.description,
                        image: _pickedImage != null ? _pickedImage : _addItem,
                      ),
                      validator: (value) {
                        if (value.isEmpty) {
                          return 'Please enter a price';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        if (double.parse(value) <= 0) {
                          return 'Please enter a number greter then zero';
                        }
                        return null;
                      },
                      onFieldSubmitted: (_) => FocusScope.of(context)
                          .requestFocus(_descriptionFocusNode),
                    ),
                    TextFormField(
                      initialValue: _initValues['description'],
                      decoration: InputDecoration(labelText: 'Description'),
                      maxLines: 3,
                      onSaved: (value) => _addItem = Item(
                        title: _addItem.title,
                        id: _addItem.id,
                        isFavorite: _addItem.isFavorite,
                        price: _addItem.price,
                        description: value,
                        image: _pickedImage != null ? _pickedImage : _addItem,
                      ),
                      validator: (value) {
                        if (value.isEmpty) {
                          return 'Please provide a description';
                        }
                        if (value.length < 10) {
                          return 'Should be at least 10 charectersling';
                        }
                        return null;
                      },
                      keyboardType: TextInputType.multiline,
                      focusNode: _descriptionFocusNode,
                    ),
                    Container(
                      width: 100,
                      height: 100,
                      margin: EdgeInsets.only(top: 8, right: 10),
                      child: ImageInput(_selectImage),
                    )
                  ],
                ),
              ),
            ),
    );
  }
}
