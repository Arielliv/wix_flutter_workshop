import 'dart:io';

    import 'package:flutter/material.dart';

    class ManageItemView extends StatelessWidget {
    final String id;
    final String title;
    final File image;

    ManageItemView(this.id, this.title, this.image);

    @override
    Widget build(BuildContext context) {
        return ListTile(
        title: Text(title),
        leading: CircleAvatar(
            backgroundImage: FileImage((image)),
        ),
        trailing: Container(
            width: 100,
            child: Row(
            children: <Widget>[
            ],
            ),
        ),
        );
    }
    }