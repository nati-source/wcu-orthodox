import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

/// Singleton that monitors network connectivity and exposes a ValueNotifier
/// so any widget can react to online/offline transitions without polling.
class ConnectivityService {
  ConnectivityService._internal();
  static final ConnectivityService instance = ConnectivityService._internal();

  final ValueNotifier<bool> isOnline = ValueNotifier(true);
  StreamSubscription<List<ConnectivityResult>>? _sub;

  /// Call once in main() after Firebase.initializeApp().
  Future<void> initialize() async {
    // Check current status immediately
    final results = await Connectivity().checkConnectivity();
    isOnline.value = _hasConnection(results);

    // Listen for future changes
    _sub = Connectivity().onConnectivityChanged.listen((results) {
      isOnline.value = _hasConnection(results);
    });
  }

  bool _hasConnection(List<ConnectivityResult> results) {
    return results.any((r) =>
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.ethernet);
  }

  void dispose() {
    _sub?.cancel();
    isOnline.dispose();
  }
}

/// A widget that shows a persistent offline banner at the top of any screen
/// whenever the device loses internet connectivity.
class OfflineAwareBanner extends StatelessWidget {
  final Widget child;
  const OfflineAwareBanner({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: ConnectivityService.instance.isOnline,
      builder: (context, online, _) {
        return Column(
          children: [
            if (!online)
              Material(
                elevation: 4,
                child: Container(
                  width: double.infinity,
                  color: const Color(0xFFB71C1C),
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                  child: const Row(
                    children: [
                      Icon(Icons.wifi_off, color: Colors.white, size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'No internet connection — ኢንተርኔት አልተገናኘም',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Expanded(child: child),
          ],
        );
      },
    );
  }
}
