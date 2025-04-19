import 'package:flutter/material.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Exemple de notifications fictives — à remplacer par les vraies plus tard
    final List<Map<String, String>> notifications = [
      {
        'title': 'New box added',
        'subtitle': 'You added “Running Shoes” to your collection.',
        'time': '2h ago'
      },
      {
        'title': 'Profile updated',
        'subtitle': 'Your email address was changed.',
        'time': 'Yesterday'
      },
      {
        'title': 'Reminder',
        'subtitle': 'Don’t forget to check your saved boxes.',
        'time': '3 days ago'
      },
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Notifications', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 60, color: Colors.grey[300]),
                  SizedBox(height: 16),
                  Text(
                    "No notifications",
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          : ListView.separated(
              itemCount: notifications.length,
              separatorBuilder: (context, index) => Divider(height: 0),
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return ListTile(
                  leading: Icon(Icons.notifications, color: Color(0xFF007BFF)),
                  title: Text(notification['title'] ?? '', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(notification['subtitle'] ?? ''),
                  trailing: Text(notification['time'] ?? '', style: TextStyle(color: Colors.grey)),
                  onTap: () {
                    // Action possible au clic
                  },
                );
              },
            ),
    );
  }
}
