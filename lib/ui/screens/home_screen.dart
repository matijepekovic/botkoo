// lib/ui/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:botko/ui/screens/connect_account_screen.dart';
import 'package:botko/ui/screens/content_library_screen.dart';
import 'package:botko/ui/screens/schedule_screen.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const Padding(
      padding: EdgeInsets.all(16.0),
      child: ConnectAccountScreen(),
    ),
    const Padding(
      padding: EdgeInsets.all(16.0),
      child: ContentLibraryScreen(),
    ),
    const Padding(
      padding: EdgeInsets.all(16.0),
      child: ScheduleScreen(),
    ),
    const _PlaceholderScreen(
      title: 'Analytics',
      icon: FontAwesomeIcons.chartLine,
      description: 'View insights and performance metrics',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Botko'),
      ),
      body: _screens[_selectedIndex],
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Botko',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Social Media Automation',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            _buildDrawerItem(
              icon: const FaIcon(FontAwesomeIcons.userPlus),
              title: 'Connect Accounts',
              index: 0,
            ),
            _buildDrawerItem(
              icon: const FaIcon(FontAwesomeIcons.folderOpen),
              title: 'Content Library',
              index: 1,
            ),
            _buildDrawerItem(
              icon: const FaIcon(FontAwesomeIcons.calendarDays),
              title: 'Schedule Posts',
              index: 2,
            ),
            _buildDrawerItem(
              icon: const FaIcon(FontAwesomeIcons.chartLine),
              title: 'Analytics',
              index: 3,
            ),
            const Divider(),
            ListTile(
              leading: const FaIcon(FontAwesomeIcons.gear),
              title: const Text('Settings'),
              onTap: () {
                // Navigate to settings
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required Widget icon,  // Changed from IconData to Widget
    required String title,
    required int index,
  }) {
    return ListTile(
      leading: icon,  // Now we can directly use the widget
      title: Text(title),
      selected: _selectedIndex == index,
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
        Navigator.pop(context);
      },
    );
  }
}

class _PlaceholderScreen extends StatelessWidget {
  final String title;
  final IconData icon;  // Keep as IconData for simplicity
  final String description;

  const _PlaceholderScreen({
    required this.title,
    required this.icon,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FaIcon(  // Changed to FaIcon to use FontAwesome
            icon,
            size: 80,
            color: Theme.of(context).colorScheme.primary.withAlpha(128),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              description,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {},
            child: const Text('Get Started'),
          ),
        ],
      ),
    );
  }
}