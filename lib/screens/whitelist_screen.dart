import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  String _searchQuery = '';
  bool _showWhitelistedOnly = false;
  static const MethodChannel _channel = MethodChannel('com.striktnanay.app/focus_mode');

  @override
  void initState() {
    super.initState();
    _loadApps();
  }

  Future<void> _loadApps() async {
    setState(() => _isLoading = true);
    _whitelistMap = await _storageService.getWhitelist();
    try {
      // Retrieve recent, launchable user apps from native (UsageStats)
      final dynamic result = await _channel.invokeMethod('getRecentApps');
      final List<dynamic> apps = (result is List) ? result : <dynamic>[];
      final list = apps.map((raw) {
        final map = Map<String, dynamic>.from(raw as Map);
        final pkg = map['packageName'] as String? ?? '';
        final name = map['appName'] as String? ?? pkg;
        return WhitelistApp(
          packageName: pkg,
          appName: name,
          icon: null,
          isWhitelisted: _whitelistMap[pkg] ?? false,
        );
      }).toList();
      list.sort((a,b)=>a.appName.compareTo(b.appName));
      debugPrint('_loadApps fetched ${list.length} apps via usage stats');
      setState(() {
        _apps = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(()=>_isLoading=false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading apps: $e')),
        );
      }
    }
  }

  List<WhitelistApp> get _filteredApps {
    Iterable<WhitelistApp> list = _apps;
    if (_showWhitelistedOnly) list = list.where((a)=>a.isWhitelisted);
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((a)=>a.appName.toLowerCase().contains(q));
    }
    return list.toList();
  }

  Future<void> _toggleWhitelist(WhitelistApp app) async {
    final newValue = !app.isWhitelisted;
    _whitelistMap[app.packageName] = newValue;
    final idx = _apps.indexWhere((a)=>a.packageName==app.packageName);
    if (idx!=-1) {
      _apps[idx] = app.copyWith(isWhitelisted: newValue);
      await _storageService.saveWhitelist(_whitelistMap);
      setState((){});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Whitelist Apps'),
        actions: [
          IconButton(
            tooltip: _showWhitelistedOnly ? 'Show all apps' : 'Show only whitelisted',
            icon: Icon(_showWhitelistedOnly ? Icons.filter_alt_off : Icons.filter_alt),
            onPressed: () => setState(()=>_showWhitelistedOnly = !_showWhitelistedOnly),
          ),
          IconButton(
            tooltip: 'Refresh list',
            icon: const Icon(Icons.refresh),
            onPressed: _loadApps,
          ),
        ],
      ),
      body: _isLoading ? const Center(child: CircularProgressIndicator()) : Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16,12,16,8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search apps',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (v)=>setState(()=>_searchQuery=v.trim()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('${_filteredApps.length} of ${_apps.length} apps', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            ),
          ),
          Expanded(
            child: _filteredApps.isEmpty ? const Center(child: Text('No apps found', style: TextStyle(color: Colors.grey))) : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _filteredApps.length,
              itemBuilder: (context,index){
                final app = _filteredApps[index];
                return _buildAppItem(app);
              },
            ),
          ),
        ],
      ),
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
        boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 6, offset: Offset(0,2))],
      ),
      child: Row(
        children: [
          if (app.icon != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(
                app.icon!,
                width: 48,
                height: 48,
                errorBuilder: (_, __, ___) => _fallbackIcon(),
              ),
            )
          else _fallbackIcon(),
          const SizedBox(width: 16),
          Expanded(
            child: Text(app.appName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF333333))),
          ),
          Switch(
            value: app.isWhitelisted,
            onChanged: (_)=>_toggleWhitelist(app),
            activeColor: Colors.white,
            activeTrackColor: const Color(0xFF00C853),
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: const Color(0xFFE0E0E0),
          ),
        ],
      ),
    );
  }

  Widget _fallbackIcon() => Container(
    width: 48,
    height: 48,
    decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(8)),
    child: const Icon(Icons.android),
  );
}

