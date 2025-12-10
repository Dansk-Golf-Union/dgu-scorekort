import 'package:flutter/material.dart';
import '../services/cache_seed_service.dart';
import '../services/course_cache_service.dart';
import '../theme/app_theme.dart';

/// Screen for managing the course cache
/// Allows seeding, viewing cache info, and clearing cache
class CacheManagementScreen extends StatefulWidget {
  const CacheManagementScreen({super.key});

  @override
  State<CacheManagementScreen> createState() => _CacheManagementScreenState();
}

class _CacheManagementScreenState extends State<CacheManagementScreen> {
  final CacheSeedService _seedService = CacheSeedService();
  final CourseCacheService _cacheService = CourseCacheService();
  
  CacheInfo? _cacheInfo;
  bool _isLoading = false;
  bool _isSeeding = false;
  List<String> _progressMessages = [];
  SeedResult? _lastSeedResult;

  @override
  void initState() {
    super.initState();
    _loadCacheInfo();
    _testFirestoreAccess();
  }

  Future<void> _testFirestoreAccess() async {
    final hasAccess = await _cacheService.testFirestoreAccess();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            hasAccess 
                ? '✅ Firestore access verified' 
                : '❌ Firestore access test failed',
          ),
          backgroundColor: hasAccess ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _loadCacheInfo() async {
    setState(() => _isLoading = true);
    
    final info = await _seedService.getCacheInfo();
    
    setState(() {
      _cacheInfo = info;
      _isLoading = false;
    });
  }

  Future<void> _seedCache() async {
    // Confirm first
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seed Cache'),
        content: const Text(
          'Dette vil hente ALLE klubber og baner fra API\'et.\n\n'
          'Det tager 2-5 minutter.\n\n'
          'Fortsæt?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuller'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.dguGreen,
            ),
            child: const Text('Start'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isSeeding = true;
      _progressMessages = [];
      _lastSeedResult = null;
    });

    final result = await _seedService.seedCache(
      onProgress: (message) {
        setState(() {
          _progressMessages.add(message);
        });
      },
    );

    setState(() {
      _isSeeding = false;
      _lastSeedResult = result;
    });

    await _loadCacheInfo();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.success 
                ? '✅ Cache seeded successfully!' 
                : '❌ Seeding failed: ${result.error}',
          ),
          backgroundColor: result.success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _clearCache() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ryd Cache'),
        content: Text(
          'Dette vil slette ALLE ${_cacheInfo?.clubCount ?? 0} klubber fra cachen.\n\n'
          'Du skal seede cachen igen bagefter.\n\n'
          'Fortsæt?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuller'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Ryd Alt'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isSeeding = true; // Disable buttons during clear
      _progressMessages = ['🗑️ Rydder cache...'];
      _lastSeedResult = null;
    });

    final success = await _seedService.clearCache();
    await _loadCacheInfo();

    setState(() {
      _isSeeding = false;
    });

    if (mounted) {
      if (success) {
        setState(() {
          _progressMessages.add('✅ Cache ryddet - seed nu med NY struktur!');
        });
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? '✅ Cache ryddet - seed nu!' : '❌ Failed to clear cache'),
          backgroundColor: success ? Colors.orange : Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Cache Management'),
        backgroundColor: AppTheme.dguGreen,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Cache Info Card
                  _buildCacheInfoCard(),
                  
                  const SizedBox(height: 16),
                  
                  // Seed Button
                  FilledButton.icon(
                    onPressed: _isSeeding ? null : _seedCache,
                    icon: _isSeeding 
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.cloud_download),
                    label: Text(_isSeeding ? 'Seeding...' : 'Seed Cache'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.dguGreen,
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Clear Cache Button
                  OutlinedButton.icon(
                    onPressed: _isSeeding ? null : _clearCache,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Ryd Cache'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                  
                  // Progress Messages
                  if (_isSeeding) ...[
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Progress:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ..._progressMessages.skip(_progressMessages.length > 10 ? _progressMessages.length - 10 : 0).map(
                              (msg) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(
                                  msg,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  
                  // Last Seed Result
                  if (_lastSeedResult != null) ...[
                    const SizedBox(height: 16),
                    Card(
                      color: _lastSeedResult!.success 
                          ? Colors.green.shade50 
                          : Colors.red.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _lastSeedResult!.success ? '✅ Success' : '❌ Failed',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _lastSeedResult!.success 
                                    ? Colors.green.shade900 
                                    : Colors.red.shade900,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text('Clubs: ${_lastSeedResult!.clubCount}'),
                            Text('Courses: ${_lastSeedResult!.courseCount}'),
                            Text('Time: ${_lastSeedResult!.duration.inSeconds}s'),
                            if (_lastSeedResult!.skippedClubs.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Skipped ${_lastSeedResult!.skippedClubs.length} large clubs:',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              ..._lastSeedResult!.skippedClubs.map((club) => 
                                Text('  • $club', style: const TextStyle(fontSize: 12)),
                              ),
                            ],
                            if (_lastSeedResult!.error != null)
                              Text(
                                'Error: ${_lastSeedResult!.error}',
                                style: TextStyle(color: Colors.red.shade900),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildCacheInfoCard() {
    if (_cacheInfo == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No cache data found'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _cacheInfo!.isValid ? Icons.check_circle : Icons.warning,
                  color: _cacheInfo!.isValid ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 8),
                Text(
                  'Cache Status',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Clubs', '${_cacheInfo!.clubCount}'),
            _buildInfoRow('Courses', '${_cacheInfo!.courseCount}'),
            _buildInfoRow('Last Updated', 
              _cacheInfo!.lastUpdated != null 
                  ? '${_cacheInfo!.ageInHours}h ago' 
                  : 'Never'),
            _buildInfoRow('Valid', _cacheInfo!.isValid ? 'Yes (<24h)' : 'No (>24h)'),
            _buildInfoRow('Version', 'v${_cacheInfo!.version}'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

