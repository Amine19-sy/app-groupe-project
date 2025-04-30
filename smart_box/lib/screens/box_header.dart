import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_box/bloc/cubits/collab_cubit.dart';
import 'package:smart_box/bloc/states/collab_states.dart';
import 'package:smart_box/models/box.dart';
import 'package:smart_box/models/user.dart';

class BoxHeader extends StatefulWidget {
  final Box box;
  const BoxHeader({Key? key, required this.box}) : super(key: key);

  @override
  _BoxHeaderState createState() => _BoxHeaderState();
}

class _BoxHeaderState extends State<BoxHeader> {
  @override
  void initState() {
    super.initState();
    // Delay fetch to ensure context is fully ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CollaboratorsCubit>().fetchCollaborators(widget.box.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Top colored header
        Stack(
          children: [
            Container(
              height: 180,
              color: Colors.blueAccent,
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star, size: 60, color: Colors.white),
                  const SizedBox(height: 8),
                  Text(
                    widget.box.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        // Description
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            widget.box.description,
            style: const TextStyle(fontSize: 16, height: 1.5),
          ),
        ),

        const Divider(),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Collaborators',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Collaborators list
        SizedBox(
          height: 80,
          child: BlocBuilder<CollaboratorsCubit, CollaboratorsState>(
            builder: (ctx, state) {
              if (state is CollaboratorsLoading) {
                return const Center(child: CircularProgressIndicator());
              } else if (state is CollaboratorsError) {
                return Center(child: Text('Error: ${state.message}'));
              } else if (state is CollaboratorsLoaded) {
                final users = state.users;
                if (users.isEmpty) {
                  return const Center(child: Text('No collaborators yet.'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (_, i) {
                    final User u = users[i];
                    return Column(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          child: Text(u.username[0].toUpperCase()),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          u.username,
                          style: const TextStyle(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemCount: users.length,
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
