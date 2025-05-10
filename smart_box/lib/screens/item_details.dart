import 'package:flutter/material.dart';
import 'package:smart_box/models/item.dart';

class ItemDetails extends StatelessWidget {
  final Item item;
  const ItemDetails({Key? key, required this.item}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height * 0.4;
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(title: Text(item.name), backgroundColor: Colors.white),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image with gradient overlay and title
              Stack(
                children: [
                  // Gradient mask over image
                  ShaderMask(
                    shaderCallback: (Rect bounds) {
                      return LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.9),
                        ],
                      ).createShader(bounds);
                    },
                    blendMode: BlendMode.dstIn,
                    child:
                        item.imagePath != null && item.imagePath!.isNotEmpty
                            ? Image.network(
                              item.imagePath!,
                              width: double.infinity,
                              fit: BoxFit.fitWidth,
                            )
                            : Container(
                              height: height,
                              width: double.infinity,
                              color: Colors.grey[200],
                              child: Icon(
                                Icons.image_not_supported,
                                size: 60,
                                color: Colors.grey,
                              ),
                            ),
                  ),
                  // Title positioned at bottom of the image
                  Positioned(
                    left: 16,
                    bottom: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      color: Colors.black45,
                      child: Text(item.name),
                    ),
                  ),
                ],
              ),
              // Details below
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Added on: ${item.addedAt.toLocal().toString().split(' ').first}',
                      style: TextStyle(color: Colors.green),
                    ),
                    const SizedBox(height: 12),
                    Text(item.description == null ? 'No Description' : item.description.toString()),
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
