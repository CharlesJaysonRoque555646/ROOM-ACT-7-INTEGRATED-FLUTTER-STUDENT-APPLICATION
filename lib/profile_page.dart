import 'package:flutter/material.dart';

import 'demo_auth.dart';
import 'login_screen.dart';

class ProfilePage extends StatelessWidget {
  final String username;

  const ProfilePage({super.key, required this.username});

  void logout(BuildContext context) {
    DemoAuth.logout();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Student Profile')),
      body: Content(username: username, onLogout: () => logout(context)),
    );
  }
}

class Content extends StatelessWidget {
  final String username;
  final VoidCallback onLogout;

  const Content({super.key, required this.username, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 20),

          const CircleAvatar(
            radius: 50,
            backgroundColor: Colors.blue,
            child: Text(
              'CJ',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            'Charles Jayson R Roque',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 10),

          const Text('BSIT', style: TextStyle(fontSize: 20)),

          const SizedBox(height: 8),
          Text('Logged in as: $username', textAlign: TextAlign.center),

          const SizedBox(height: 5),

          const Text('Student No. 555646', style: TextStyle(fontSize: 18)),

          const SizedBox(height: 5),

          Card(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            child: const Column(
              children: [
                ListTile(
                  leading: Icon(Icons.school),
                  title: Text('Year Level'),
                  subtitle: Text('3rd Year'),
                ),
                ListTile(
                  leading: Icon(Icons.badge),
                  title: Text('Code'),
                  subtitle: Text('3447'),
                ),
                ListTile(
                  leading: Icon(Icons.email),
                  title: Text('School Email'),
                  subtitle: Text('c.roque.555646@umindanao.edu.ph'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onLogout,
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
          ),
          const SizedBox(height: 20),

          Card(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'About Me',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'I am an IT student with a passion for technology and programming. I enjoy exploring new technologies and developing innovative solutions to real-world problems. In my free time, I like to play video games and engage in various hobbies that allow me to express my creativity.',
                    style: TextStyle(fontSize: 16),
                    textAlign: TextAlign.justify,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          Card(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hobbies & Interests',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  ListTile(
                    leading: Icon(Icons.games, color: Colors.blue),
                    title: Text('Playing Video Games'),
                  ),
                  ListTile(
                    leading: Icon(Icons.code, color: Colors.blue),
                    title: Text('Programming'),
                  ),
                  ListTile(
                    leading: Icon(Icons.science, color: Colors.blue),
                    title: Text('Exploring scientific things'),
                  ),
                  ListTile(
                    leading: Icon(Icons.movie, color: Colors.blue),
                    title: Text('Watching Movies/Anime'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
