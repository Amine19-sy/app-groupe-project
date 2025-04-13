import 'package:anim_search_bar/anim_search_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:smart_box/bloc/cubits/home_cubit.dart';
import 'package:smart_box/bloc/states/home_states.dart';
import 'package:smart_box/screens/add_box.dart';
import 'package:smart_box/services/box_service.dart';
import 'package:smart_box/widgets/animated_search_bar.dart';




class HomePage extends StatelessWidget {
  final Map<String, dynamic> user;
  
  HomePage({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String userId = user['user']["id"].toString();
    final boxService = BoxService();
    return BlocProvider<HomeCubit>(
      create: (_) => HomeCubit(userId: userId, boxService: boxService)
        ..fetchUserBoxes(),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(title: Text('Home',),backgroundColor: Colors.white,),
        drawer: Drawer(
  child: ListView(
    padding: EdgeInsets.zero,
    children: <Widget>[
      UserAccountsDrawerHeader(
        accountName: Text(user["user"]["username"].toString()),
        accountEmail: Text(user["user"]["email"].toString()),
        // currentAccountPicture: CircleAvatar(
        //   backgroundImage: NetworkImage('https://example.com/profile_image.png'),
        // ),
        decoration: BoxDecoration(
          color: Colors.blue,
        ),
      ),
      ListTile(
        leading: Icon(Icons.notifications),
        title: Text('Notification'),
      ),
      ExpansionTile(
        leading: Icon(Icons.sunny),
        title: Text('Theme'),
        children: [
          ListTile(
            title: Text("Dark"),
          ),
          ListTile(
            title: Text("Light"),
          ),
        ],
      ),
       ExpansionTile(
        leading: Icon(Icons.language),
        title: Text("Language"),
        children: [
          ListTile(
            title: Text("English"),
          ),
          ListTile(
            title: Text("French"),
          ),
        ],
      ),
      ListTile(
        leading: Icon(Icons.notifications),
        title: Text('Threasholds'),
      ),
      ListTile(
        leading: Icon(Icons.notifications),
        title: Text('Settings'),
      ),
      Divider(),
      ListTile(
        leading: Icon(Icons.logout),
        title: Text('Log out',style:TextStyle(color:Colors.red),),
      )
      
    ],
  ),
),

        body: BlocBuilder<HomeCubit, HomeState>(
          builder: (context, state) {
            if (state is HomeLoading) {
              return Center(child: CircularProgressIndicator());
            } else if (state is HomeEmpty) {
              return 
              Center(child:Column(children:[
                Image.asset("assets/img/out-of-stock.png",height: 60,width:60),
                SizedBox(height:16),
                Text("Looks a bit empty",style: TextStyle(color: Colors.grey),)
              ],mainAxisAlignment: MainAxisAlignment.center,crossAxisAlignment: CrossAxisAlignment.center,));
            } else if (state is HomeLoaded) {
              return  ListView.builder(
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
        title: Text(box.name ?? 'Unnamed Box'),
        subtitle: Text(box.description ?? 'No description'),
        trailing: Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          // You can navigate to a detail screen if needed
        },
      ),
    );
  },
);
;
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
        builder: (_) => AddBoxForm(userId: user['user']['id'].toString()),
      ),
    );
    // context.read<HomeCubit>().fetchUserBoxes();
    // if (newBox != null) {
    //   context.read<HomeCubit>().fetchUserBoxes();
    // }
       },
          child: Icon(Icons.add),
        ),
      ),
    );
  }
}

