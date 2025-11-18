import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart';
import '../models/whitelist_app.dart';
import '../services/storage_service.dart';

class WhitelistScreen extends StatefulWidget {
  const WhitelistScreen({super.key});

  @override
  State<WhitelistScreen> createState() => _WhitelistScreenState();
}

class _WhitelistScreenState extends State<WhitelistScreen> {
  final StorageService _storageService = StorageService();
  List<WhitelistApp> _apps = [];
  bool _isLoading = true;
  Map<String, bool> _whitelistMap = {};

  @override
  void initState() {
    super.initState();
    _loadApps();
  }

  Future<void> _loadApps() async {
    setState(() => _isLoading = true);

    // Load existing whitelist
    _whitelistMap = await _storageService.getWhitelist();

    // Get installed apps using maintained installed_apps plugin
    try {
      final installedApps = await InstalledApps.getInstalledApps(
        excludeSystemApps: true,
        excludeNonLaunchableApps: true,
        withIcon: true,
      );
      final appsList = <WhitelistApp>[];
      for (final AppInfo app in installedApps) {
        Uint8List? iconBytes = app.icon; // May be null
        appsList.add(WhitelistApp(
          packageName: app.packageName,
          appName: app.name,
          icon: iconBytes,
          isWhitelisted: _whitelistMap[app.packageName] ?? false,
        ));
      }
      appsList.sort((a, b) => a.appName.compareTo(b.appName));
      setState(() {
        _apps = appsList;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading apps: $e')),
        );
      }
    }
  }

  Future<void> _toggleWhitelist(WhitelistApp app) async {
    final newValue = !app.isWhitelisted;
    _whitelistMap[app.packageName] = newValue;

    final index = _apps.indexWhere((a) => a.packageName == app.packageName);
    if (index != -1) {
      _apps[index] = app.copyWith(isWhitelisted: newValue);
      await _storageService.saveWhitelist(_whitelistMap);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Whitelist',
          style: TextStyle(
            color: Color(0xFF333333),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
        body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Profile section
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.grey[300]!,
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.person,
                          color: Color(0xFF0D7377),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        'Strikt Nanay',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF333333),
                        ),
                      ),
                    ],
                  ),
                ),
                
                
                // Apps list
                Expanded(
                  child: _apps.isEmpty
                      ? const Center(
                          child: Text(
                            'No apps found',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: _apps.length,
                          itemBuilder: (context, index) {
                            final app = _apps[index];
                            return _buildAppItem(app);
                          },
                        ),
                ),
              ],
            ),
      // Removed bottom-right FAB per request
    );
  }

  Widget _buildAppItem(WhitelistApp app) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // App icon
          if (app.icon != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(
                app.icon!,
                width: 48,
                height: 48,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.android),
                  );
                },
              ),
            )
          else
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.android),
            ),
          
          const SizedBox(width: 16),
          
          // App name
          Expanded(
            child: Text(
              app.appName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF333333),
              ),
            ),
          ),
          
          // Toggle switch
          Switch(
            value: app.isWhitelisted,
            onChanged: (_) => _toggleWhitelist(app),
            activeColor: Colors.white,
            activeTrackColor: const Color(0xFF00C853),
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: const Color(0xFFE0E0E0),
          ),
        ],
      ),
    );
  }
}

