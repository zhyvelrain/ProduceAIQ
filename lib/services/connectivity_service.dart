import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Tracks the device's actual network state so UI components can reflect
/// whether the device is online (has an active internet connection) or
/// offline (no connection). The app runs inference on-device, so offline
/// does NOT mean the app is broken -- it just means the AI recipe
/// suggestions feature (which calls the Apps Script proxy) will use its
/// curated fallback list instead.
class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._();

  static ConnectivityService get instance => _instance;

  factory ConnectivityService() => _instance;

  ConnectivityService._() {
    _init();
  }

  late final _controller = StreamController<String>.broadcast();
  Stream<String> get onStatusChanged => _controller.stream;

  String _currentStatus = 'unknown';
  bool _isOnline = false;

  bool get isOnline => _isOnline;

  Future<void> _init() async {
    final Connectivity connectivity = Connectivity();
    // Ignore false positives: only treat 'wifi' and 'mobile' as online.
    connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) {
      final result = _resultsToString(results);
      _updateStatus(result);
    });
    // Probe once on startup so the indicator reflects the initial state.
    final initial = _resultsToString(await connectivity.checkConnectivity());
    _updateStatus(initial);
    // Do an actual internet reachability check on startup and periodically
    _checkInternetReachability();
    Timer.periodic(const Duration(seconds: 30), (_) => _checkInternetReachability());
  }

  /// Map ConnectivityResult list to a single status string.
  String _resultsToString(List<ConnectivityResult> results) {
    if (results.contains(ConnectivityResult.none)) return 'offline';
    if (results.contains(ConnectivityResult.wifi)) return 'online';
    if (results.contains(ConnectivityResult.mobile)) return 'online';
    // Cellular + wifi both fine, or any other combination that isn't none.
    return 'online';
  }

  /// Actual internet reachability check (not just network interface)
  Future<void> _checkInternetReachability() async {
    try {
      // Use a lightweight HTTP HEAD request to a reliable endpoint
      final uri = Uri.parse('https://www.google.com/generate_204');
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 5)
        ..idleTimeout = const Duration(seconds: 5);
      final request = await client.headUrl(uri);
      final response = await request.close();
      final hasInternet = response.statusCode == 204;
      client.close();
      _updateStatus(hasInternet ? 'online' : 'offline');
    } catch (_) {
      // Any error means no internet reachability
      _updateStatus('offline');
    }
  }

  void _updateStatus(String status) {
    _currentStatus = status;
    _isOnline = status == 'online';
    _controller.add(status);
  }

  /// Returns the current status string: 'online', 'offline', or 'unknown'.
  String get status => _currentStatus;
}
