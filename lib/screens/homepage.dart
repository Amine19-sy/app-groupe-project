import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_box/bloc/cubits/home_cubit.dart';
import 'package:smart_box/bloc/states/home_states.dart';
import 'package:smart_box/backend/Item_Box.dart';
import 'package:smart_box/screens/add_box.dart';

class HomePage extends StatelessWidget {
  final Map<String, dynamic> user;

  HomePage({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String userId = user["id"].toString();
    final boxService = ItemBoxService();

    return BlocProvider<HomeCubit>(
      create: (_) => HomeCubit(userId: userId, boxService: boxService)..fetchUserBoxes(),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text('Home'),
          backgroundColor: Colors.white,
        ),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              UserAccountsDrawerHeader(
                accountName: Text(user["username"].toString()),
                accountEmail: Text(user["email"].toString()),  
                decoration: BoxDecoration(color: Colors.blue),
              ),
              ListTile(leading: Icon(Icons.notifications), title: Text('Notification')),
              ExpansionTile(
                leading: Icon(Icons.sunny),
                title: Text('Theme'),
                children: [
                  ListTile(title: Text("Dark")),
                  ListTile(title: Text("Light")),
                ],
              ),
              ExpansionTile(
                leading: Icon(Icons.language),
                title: Text("Language"),
                children: [
                  ListTile(title: Text("English")),
                  ListTile(title: Text("French")),
                ],
              ),
              ListTile(leading: Icon(Icons.settings), title: Text('Thresholds')),
              ListTile(leading: Icon(Icons.settings), title: Text('Settings')),
              Divider(),
              ListTile(
                leading: Icon(Icons.logout),
                title: Text('Log out', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ),
        body: BlocBuilder<HomeCubit, HomeState>(
          builder: (context, state) {
            if (state is HomeLoading) {
              return Center(child: CircularProgressIndicator());
            } else if (state is HomeEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset("assets/img/out-of-stock.png", height: 60, width: 60),
                    SizedBox(height: 16),
                    Text("Looks a bit empty", style: TextStyle(color: Colors.grey)),
                  ],
                ),
              );
            } else if (state is HomeLoaded) {
              return ListView.builder(
                padding: EdgeInsets.all(12),
                itemCount: state.boxes.length,
                itemBuilder: (context, index) {
                  final box = state.boxes[index];
                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    margin: EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      leading: Icon(Icons.inventory_2, color: Colors.blue),
                      title: Text(box.name),
                      subtitle: Text(box.description ?? 'No description'),
                      trailing: Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                      },
                    ),
                  );
                },
              );
            } else if (state is HomeError) {
              return Center(child: Text(state.message));
            }
            return Container();
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            final newBox = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AddBoxForm(userId: userId),
              ),
            );
            if (newBox != null) {
              context.read<HomeCubit>().fetchUserBoxes();
            }
          },
          child: Icon(Icons.add),
        ),
      ),
    );
  }
}
