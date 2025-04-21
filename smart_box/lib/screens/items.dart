import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_box/bloc/cubits/items_cubits.dart';
import 'package:smart_box/bloc/states/items_states.dart';
import 'package:smart_box/models/item.dart';
import 'package:smart_box/screens/add_item.dart';
import 'package:smart_box/services/item_service.dart';

class Items extends StatefulWidget {
  final int boxId;
  final int userId;
  const Items({super.key, required this.boxId,required this.userId});

  @override
  State<Items> createState() => _ItemsState();
}

class _ItemsState extends State<Items> {
  late Future<List<Item>> _itemsFuture;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  void _loadItems() {
    _itemsFuture = ItemService().getItems(widget.boxId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocBuilder<ItemsCubit, ItemsState>(
        builder: (context, state) {
          if (state is ItemsLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is ItemsError) {
            return _EmptyState(
              image: 'assets/img/error.png',
              message: state.message,
              color: Colors.red,
            );
          } else if (state is ItemsLoaded) {
            final items = state.items;
            if (items.isEmpty) {
              return _EmptyState(
                image: 'assets/img/out-of-stock.png',
                message: 'Looks a bit empty',
              );
            }
            return ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child:
                              item.imagePath != null
                                  ? Image.network(
                                    item.imagePath!,
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                  )
                                  : Icon(
                                    Icons.image_not_supported,
                                    size: 60,
                                    color: Colors.grey,
                                  ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Added: ${item.addedAt.toString().substring(0, 10)}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            context.read<ItemsCubit>().removeItem(
                              itemId: item.id,
                              userId: widget.userId, 
                              boxId: int.parse(item.boxId),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }
          // initial state
          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => AddItemScreen(boxId: widget.boxId, userId: '1'),
            ),
          );

          if (result == true) {
            context.read<ItemsCubit>().getItems(widget.boxId);
          }
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String image;
  final String message;
  final Color? color;

  const _EmptyState({
    Key? key,
    required this.image,
    required this.message,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(image, height: 60, width: 60),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: color ?? Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
