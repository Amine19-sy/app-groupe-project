import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  final Map<String, dynamic> user;

  const ProfilePage({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Profile', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Info Section
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Color(0xFF007BFF),
                  child: Icon(Icons.person, size: 30, color: Color(0xFF007BFF)),
                ),
                SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user['username'] ?? 'Username',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      user['email'] ?? 'email@example.com',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                )
              ],
            ),
            SizedBox(height: 30),

            // Profile options
            _buildOption(icon: Icons.settings, title: 'Account Settings'),
            _buildOption(icon: Icons.lock, title: 'Change Password'),
            _buildOption(icon: Icons.notifications, title: 'Notifications'),
            _buildOption(icon: Icons.help_outline, title: 'Help & Support'),
            _buildOption(icon: Icons.info_outline, title: 'About'),

            Spacer(),

            Center(
              child: TextButton.icon(
                onPressed: () {
                  // Add logout logic here
                },
                icon: Icon(Icons.logout, color: Colors.red),
                label: Text('Log out', style: TextStyle(color: Colors.red)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildOption({required IconData icon, required String title}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: Color(0xFF007BFF)),
      title: Text(title, style: TextStyle(fontSize: 16)),
      trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: () {
        // Navigation or logic
      },
    );
  }
}
