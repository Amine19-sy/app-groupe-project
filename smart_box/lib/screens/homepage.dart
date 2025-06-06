import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_box/bloc/cubits/home_cubit.dart';
import 'package:smart_box/bloc/cubits/req_rec.dart';
import 'package:smart_box/bloc/cubits/req_sent.dart';
import 'package:smart_box/bloc/cubits/sharedboxes_cubit.dart';
import 'package:smart_box/bloc/states/home_states.dart';
import 'package:smart_box/bloc/states/sharedboxes_states.dart';
import 'package:smart_box/screens/add_box.dart';
import 'package:smart_box/screens/box_details.dart';
import 'package:smart_box/screens/login_form.dart';
import 'package:smart_box/screens/req_rec.dart';
import 'package:smart_box/screens/req_sent.dart';
import 'package:smart_box/screens/search_screen.dart';
import 'package:smart_box/services/auth_service.dart';
import 'package:smart_box/services/box_service.dart';
import 'package:smart_box/widgets/box_widget.dart';


class HomePage extends StatefulWidget {
  final Map<String, dynamic> user;
  const HomePage({Key? key, required this.user}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  late final int _userId;
  late HomeCubit _homeCubit;
  late SharedBoxesCubit _sharedBoxesCubit;

  @override
  void initState() {
    super.initState();
    _userId = widget.user['user']['id'];
    // Initialize the cubits here
    _homeCubit = HomeCubit(
      authService: AuthService(),
      boxService: BoxService(),
      userId: _userId.toString(),
    )..fetchUserBoxes();
    
    _sharedBoxesCubit = SharedBoxesCubit(BoxService())..fetchSharedBoxes(_userId);
  }
  
  @override
  void dispose() {
    // Clean up cubits when the widget is disposed
    _homeCubit.close();
    _sharedBoxesCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(
          value: _homeCubit,
        ),
        BlocProvider.value(
          value: _sharedBoxesCubit,
        ),
      ],
      child: BlocListener<HomeCubit, HomeState>(
        listener: (context, state) {
          if (state is HomeLoggedOut) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => LoginForm()),
              (route) => false,
            );
          }
        },
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            title: const Text('Home', style: TextStyle(color: Colors.black)),
            actions: [
              IconButton(
                icon: const Icon(Icons.search, color: Colors.black),
                onPressed: () {
                  Navigator.of(context).push(
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          SearchScreen(userId: _userId.toString()),
                      transitionDuration: const Duration(milliseconds: 300),
                      transitionsBuilder: (
                        context,
                        animation,
                        secondaryAnimation,
                        child,
                      ) {
                        final tween = Tween<Offset>(
                          begin: const Offset(1, 0),
                          end: Offset.zero,
                        ).chain(CurveTween(curve: Curves.easeOut));

                        return SlideTransition(
                          position: animation.drive(tween),
                          child: child,
                        );
                      },
                    ),
                  );
                },
              ),
            ],
          ),
          drawer: CustomDrawer(user: widget.user),
          body: IndexedStack(
            index: _currentIndex,
            children: [
              HomeContent(user: widget.user),
              SharedBoxesContent(userId: _userId),
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            backgroundColor: Colors.white,
            currentIndex: _currentIndex,
            onTap: (i) => setState(() => _currentIndex = i),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.inbox),
                label: 'My Boxes',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.group_work),
                label: 'Shared',
              ),
            ],
          ),
          floatingActionButton: _currentIndex == 0
              ? FloatingActionButton(
                  onPressed: () async {
                    final result = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddBoxForm(userId: _userId.toString()),
                      ),
                    );
                    
                    if (result == true) {
                      // Use the class instance directly instead of context.read
                      _homeCubit.fetchUserBoxes();
                    }
                  },
                  child: const Icon(Icons.add),
                )
              : null,
        ),
      ),
    );
  }
}
class HomeContent extends StatelessWidget {
  final Map<String, dynamic> user;
  const HomeContent({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        if (state is HomeLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is HomeEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  "assets/img/out-of-stock.png",
                  height: 60,
                  width: 60,
                ),
                const SizedBox(height: 16),
                const Text(
                  "Looks a bit empty",
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        } else if (state is HomeLoaded) {
          return RefreshIndicator(
            onRefresh: () async {
              await context.read<HomeCubit>().fetchUserBoxes();
            },
            child: ListView.builder(
              // padding: const EdgeInsets.all(12),
              itemCount: state.boxes.length,
              itemBuilder: (context, index) {
                final box = state.boxes[index];
                return GestureDetector(
                  key: ValueKey(box.id),
                  child: StyledBoxCard(box: box),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BoxDetails(box: box, user: user),
                      ),
                    );
                  },
                );
              },
            ),
          );
        } else if (state is HomeError) {
          return Center(child: Text(state.message));
        }
        return Container();
      },
    );
  }
}

class SharedBoxesContent extends StatelessWidget {
  final int userId;
  const SharedBoxesContent({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SharedBoxesCubit, SharedBoxesState>(
      builder: (ctx, state) {
        if (state is SharedBoxesLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is SharedBoxesError) {
          return Center(child: Text('Error: ${state.message}'));
        }
        final boxes = (state as SharedBoxesLoaded).boxes;
        if (boxes.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  "assets/img/out-of-stock.png",
                  height: 60,
                  width: 60,
                ),
                const SizedBox(height: 16),
                const Text(
                  "Looks a bit empty",
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh:
              () => context.read<SharedBoxesCubit>().fetchSharedBoxes(userId),
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: boxes.length,
            itemBuilder: (_, i) {
              final box = boxes[i];
              return GestureDetector(
                child: StyledBoxCard(box: box),
                onTap: () {
                  // reuse your BoxDetails screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => BoxDetails(
                            box: box,
                            user: {
                              'user': {'id': userId},
                            },
                          ),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}

class CustomDrawer extends StatelessWidget {
  final Map<String, dynamic> user;

  const CustomDrawer({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          UserAccountsDrawerHeader(
            accountName: Text(user['user']['username'].toString()),
            accountEmail: Text(user['user']['email'].toString()),
            decoration: const BoxDecoration(color: Colors.blue),
          ),
          ListTile(
            leading: const Icon(Icons.insert_invitation),
            title: const Text('Invitations'),
            onTap: () async {
              final result = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder:
                      (_) => RequestsSentScreen(ownerId: user['user']['id']),
                ),
              );

              if (result == true) {
                context.read<RequestsSentCubit>().fetch(user['user']['id']);
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.request_page),
            title: const Text('Requests'),
            onTap: () async {
              final result = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder:
                      (_) => RequestsReceivedScreen(userId: user['user']['id']),
                ),
              );

              if (result == true) {
                context.read<RequestsReceivedCubit>().fetch(user['user']['id']);
              }
            },
          ),
          ExpansionTile(
            leading: const Icon(Icons.sunny),
            title: const Text('Theme'),
            children: const [
              ListTile(title: Text('Dark')),
              ListTile(title: Text('Light')),
            ],
          ),
          ExpansionTile(
            leading: const Icon(Icons.language),
            title: const Text('Language'),
            children: const [
              ListTile(title: Text('English')),
              ListTile(title: Text('French')),
            ],
          ),
          ListTile(
            leading: const Icon(Icons.maximize),
            title: const Text('Thresholds'),
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
          ),
          const Divider(),
          ListTile(
            onTap: () => context.read<HomeCubit>().logout(),
            leading: const Icon(Icons.logout),
            title: const Text('Log out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
