import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_box/bloc/cubits/home_cubit.dart';
import 'package:smart_box/bloc/states/home_states.dart';
import 'package:smart_box/screens/add_box.dart';
import 'package:smart_box/screens/box_details.dart';
import 'package:smart_box/screens/login_form.dart';
import 'package:smart_box/services/box_service.dart';
import 'package:smart_box/widgets/box_widget.dart';

class HomePage extends StatefulWidget {
  final Map<String, dynamic> user;
  const HomePage({Key? key, required this.user}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isSearching = false;
  final TextEditingController searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final String userId = widget.user['user']["id"].toString();
    final boxService = BoxService();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        // Toggle between the search AppBar and the normal AppBar.
        title: isSearching ? _buildSearchField() : _buildNormalTitle(),
        actions: _buildAppBarActions(),
      ),
      drawer: isSearching ? null : CustomDrawer(user: widget.user),
      body: isSearching
          ? SearchScreenWidget(
              searchController: searchController,
            )
          : HomeContent(user: widget.user),
      floatingActionButton: isSearching
          ? null
          : FloatingActionButton(
              onPressed: () async {
                final didAdd = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddBoxForm(
                        userId: widget.user['user']['id'].toString()),
                  ),
                );
                if (didAdd == true) {
                  try {
                    context.read<HomeCubit>().fetchUserBoxes();
                  } catch (e) {
                    print(e);
                  }
                }
              },
              child: const Icon(Icons.add),
            ),
    );
  }

  // Returns the AppBar title widget for non-search mode.
  Widget _buildNormalTitle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Home', style: TextStyle(color: Colors.black)),
        IconButton(
          icon: const Icon(Icons.search, color: Colors.black),
          onPressed: () {
            setState(() {
              isSearching = true;
            });
          },
        ),
      ],
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: searchController,
      autofocus: true,
      decoration: const InputDecoration(
        hintText: 'Search...',
        border: InputBorder.none,
      ),
      onChanged: (value) {
        // Invoke your search logic here; for example, calling a Bloc event.
      },
    );
  }

  List<Widget>? _buildAppBarActions() {
    if (isSearching) {
      return [
        IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () {
            setState(() {
              isSearching = false;
              searchController.clear();
            });
          },
        ),
      ];
    }
    return null;
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
                )
              ],
            ),
          );
        } else if (state is HomeLoaded) {
          return RefreshIndicator(
            onRefresh: () async {
              await context.read<HomeCubit>().fetchUserBoxes();
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: state.boxes.length,
              itemBuilder: (context, index) {
                final box = state.boxes[index];
                return GestureDetector(
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


class SearchScreenWidget extends StatelessWidget {
  final TextEditingController searchController;

  const SearchScreenWidget({Key? key, required this.searchController})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Search Screen'),
          // Optionally, use a widget to display search suggestions or results:
          // Expanded(child: SearchResultsWidget(query: searchController.text)),
        ],
      ),
    );
  }
}

class CustomDrawer extends StatelessWidget {
  final Map<String, dynamic> user;

  const CustomDrawer({Key? key, required this.user}) : super(key: key);
void _logout(BuildContext context) {
    // Optionally: Clear any secure storage or user session here
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginForm()),
      (route) => false, // removes all previous routes
    );
  }
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          UserAccountsDrawerHeader(
            accountName: Text(user["user"]["username"].toString()),
            accountEmail: Text(user["user"]["email"].toString()),
            decoration: const BoxDecoration(
              color: Colors.blue,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Notification'),
          ),
          ExpansionTile(
            leading: const Icon(Icons.sunny),
            title: const Text('Theme'),
            children: const [
              ListTile(
                title: Text("Dark"),
              ),
              ListTile(
                title: Text("Light"),
              ),
            ],
          ),
          ExpansionTile(
            leading: const Icon(Icons.language),
            title: const Text("Language"),
            children: const [
              ListTile(
                title: Text("English"),
              ),
              ListTile(
                title: Text("French"),
              ),
            ],
          ),
          ListTile(
            leading: const Icon(Icons.maximize),
            title: const Text('Threasholds'),
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
          ),
          const Divider(),
          ListTile(
            onTap: () => _logout(context),
            leading: const Icon(Icons.logout),
            title: const Text(
              'Log out',
              style: TextStyle(color: Colors.red),
              
            ),
          ),
        ],
      ),
    );
  }
}
