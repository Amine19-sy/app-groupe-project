import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_box/backend/Item_Box.dart';
import 'package:smart_box/bloc/cubits/home_cubit.dart';
import 'package:smart_box/bloc/states/home_states.dart';
import 'package:smart_box/screens/box.dart';

class HomeContent extends StatelessWidget {
  final Map<String, dynamic> user;

  const HomeContent({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String userId = user["id"].toString();
    final boxService = ItemBoxService();

    return BlocProvider<HomeCubit>(
      create: (_) => HomeCubit(userId: userId, boxService: boxService)..fetchUserBoxes(),
      child: BlocBuilder<HomeCubit, HomeState>(
        builder: (context, state) {
          if (state is HomeLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is HomeEmpty) {
            return Center(
              child: Text(
                "No boxes found.",
                style: TextStyle(color: Colors.grey[600]),
              ),
            );
          }

          if (state is HomeLoaded) {
            return Padding(
              padding: const EdgeInsets.all(12.0),
              child: GridView.builder(
                itemCount: state.boxes.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 3 / 3.2,
                ),
                itemBuilder: (context, index) {
                  final box = state.boxes[index];
                  return BoxCard(
                    title: box.name,
                    boxId: box.id,
                    imageUrl: null,
                    onTap: () {
                      // Optionally handle tap
                    },
                  );
                },
              ),
            );
          }

          if (state is HomeError) {
            return Center(child: Text(state.message));
          }

          return Container();
        },
      ),
    );
  }
}
