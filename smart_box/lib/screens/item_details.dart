import 'package:flutter/material.dart';
import 'package:smart_box/models/item.dart';

class ItemDetails extends StatelessWidget {
  final Item item;
  const ItemDetails({Key? key, required this.item}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(title: Text(item.name)),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Display the image full width with fixed height and cover fit
              item.imagePath != null && item.imagePath!.isNotEmpty
                  ? Image.network(
                    item.imagePath!,
                    width: double.infinity,
                    height: 250,
                    fit: BoxFit.cover,
                  )
                  : Container(
                    width: double.infinity,
                    height: 250,
                    color: Colors.grey[200],
                    child: Icon(
                      Icons.image_not_supported,
                      size: 60,
                      color: Colors.grey,
                    ),
                  ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      item.addedAt.toString(),
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
