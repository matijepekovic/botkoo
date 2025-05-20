import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:botko/core/providers/account_provider.dart';
import 'package:botko/core/models/social_account.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ConnectAccountScreen extends StatefulWidget {
  const ConnectAccountScreen({super.key});

  @override
  State<ConnectAccountScreen> createState() => _ConnectAccountScreenState();
}

class _ConnectAccountScreenState extends State<ConnectAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  String _selectedPlatform = 'twitter';
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  final List<Map<String, dynamic>> _platforms = [
    {'value': 'twitter', 'label': 'X', 'icon': FontAwesomeIcons.xTwitter},
    {'value': 'facebook', 'label': 'Facebook', 'icon': FontAwesomeIcons.facebook},
    {'value': 'instagram', 'label': 'Instagram', 'icon': FontAwesomeIcons.instagram},
    {'value': 'linkedin', 'label': 'LinkedIn', 'icon': FontAwesomeIcons.linkedin},
    {'value': 'tiktok', 'label': 'TikTok', 'icon': FontAwesomeIcons.tiktok},
    {'value': 'threads', 'label': 'Threads', 'icon': FontAwesomeIcons.at}, // Threads doesn't have a specific icon yet
    {'value': 'youtube', 'label': 'YouTube', 'icon': FontAwesomeIcons.youtube},
  ];

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Connected accounts section
        _buildConnectedAccountsSection(),

        const SizedBox(height: 24),

        // Add new account section
        _buildAddAccountSection(),
      ],
    );
  }

  Widget _buildConnectedAccountsSection() {
    return Consumer<AccountProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.accounts.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'No accounts connected yet. Add a social media account below.',
                style: TextStyle(fontSize: 16),
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Connected Accounts',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: provider.accounts.length,
              itemBuilder: (context, index) {
                final account = provider.accounts[index];
                final platform = _platforms.firstWhere(
                      (p) => p['value'] == account.platform,
                  orElse: () => {'value': account.platform, 'label': account.platform, 'icon': Icons.account_circle},
                );

                return Card(
                  child: ListTile(
                    leading: _getPlatformIcon(account.platform),
                    title: Text(account.username),
                    subtitle: Text('${platform['label']} - Connected'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _confirmRemoveAccount(account),
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
  Widget _getPlatformIcon(String platform) {
    switch (platform) {
      case 'twitter':
        return const FaIcon(FontAwesomeIcons.xTwitter);
      case 'facebook':
        return const FaIcon(FontAwesomeIcons.facebook);
      case 'instagram':
        return const FaIcon(FontAwesomeIcons.instagram);
      case 'linkedin':
        return const FaIcon(FontAwesomeIcons.linkedin);
      case 'tiktok':
        return const FaIcon(FontAwesomeIcons.tiktok);
      case 'threads':
        return const FaIcon(FontAwesomeIcons.at); // Threads doesn't have a specific icon yet
      case 'youtube':
        return const FaIcon(FontAwesomeIcons.youtube);
      default:
        return const FaIcon(FontAwesomeIcons.globe);
    }
  }
  Widget _buildAddAccountSection() {
    return Consumer<AccountProvider>(
      builder: (context, provider, child) {
        return Form(
          key: _formKey,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Add New Account',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // Platform dropdown
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Platform',
                      border: OutlineInputBorder(),
                    ),
                    value: _selectedPlatform,
                    items: _platforms.map((platform) {
                      return DropdownMenuItem(
                        value: platform['value'] as String,
                        child: Row(
                          children: [
                            Icon(platform['icon'] as IconData, size: 20),
                            const SizedBox(width: 8),
                            Text(platform['label'] as String),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedPlatform = value;
                        });
                      }
                    },
                  ),

                  const SizedBox(height: 16),

                  // Username field
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a username';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Password field
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a password';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Error message
                  if (provider.error != null)
                    Container(
                      padding: const EdgeInsets.all(8),
                      color: Colors.red.withAlpha(50),
                      child: Text(
                        provider.error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Connect button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: provider.isLoading ? null : _connectAccount,
                      child: provider.isLoading
                          ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                          : const Text('Connect Account'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _connectAccount() {
    if (_formKey.currentState!.validate()) {
      final provider = Provider.of<AccountProvider>(context, listen: false);
      _performConnect(
        provider,
        _selectedPlatform,
        _usernameController.text,
        _passwordController.text,
      );
    }
  }

  Future<void> _performConnect(
      AccountProvider provider,
      String platform,
      String username,
      String password,
      ) async {
    await provider.connectAccount(platform, username, password);
    if (!mounted) return;

    if (provider.error == null) {
      _usernameController.clear();
      _passwordController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account connected successfully!')),
      );
    }
  }

  void _confirmRemoveAccount(SocialAccount account) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Account'),
        content: Text('Are you sure you want to remove ${account.username} from your connected accounts?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              Provider.of<AccountProvider>(context, listen: false)
                  .removeAccount(account.platform, account.username);
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}