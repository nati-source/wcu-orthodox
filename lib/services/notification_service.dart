import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Top-level background message handler required by Firebase Messaging.
/// Must be outside any class and annotated with @pragma('vm:entry-point').
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}
  debugPrint('FCM Background message received: ${message.messageId} - ${message.notification?.title}');
}

/// Production Firebase Cloud Messaging (FCM) Service for WCU Orthodox Fellowship.
/// Manages device registration tokens, push permission requests, topic subscriptions,
/// and in-app/foreground notification dispatching.
class NotificationService {
  NotificationService._internal();
  static final NotificationService instance = NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _currentToken;
  String? get currentToken => _currentToken;

  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _openedAppSubscription;
  StreamSubscription<String>? _tokenRefreshSubscription;

  /// Callback when a foreground notification is received
  Function(RemoteMessage message)? onForegroundMessageReceived;

  /// Callback when user taps a notification that opens the app
  Function(RemoteMessage message)? onNotificationOpened;

  /// Initialize FCM push notifications.
  /// Call this after [Firebase.initializeApp()] in main().
  Future<void> initialize({
    Function(RemoteMessage message)? onForegroundMessage,
    Function(RemoteMessage message)? onNotificationOpened,
  }) async {
    this.onForegroundMessageReceived = onForegroundMessage;
    this.onNotificationOpened = onNotificationOpened;

    try {
      // 1. Request notification permissions (required on iOS and Android 13+)
      final settings = await _fcm.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint('FCM Notification permission status: ${settings.authorizationStatus}');

      // 2. Set presentation options for foreground messages (iOS)
      await _fcm.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // 3. Retrieve FCM device token
      try {
        _currentToken = await _fcm.getToken();
        debugPrint('FCM Device Registration Token: $_currentToken');
      } catch (e) {
        debugPrint('FCM getToken error: $e');
      }

      // 4. Listen to token refresh
      _tokenRefreshSubscription?.cancel();
      _tokenRefreshSubscription = _fcm.onTokenRefresh.listen((newToken) {
        _currentToken = newToken;
        debugPrint('FCM Token refreshed: $newToken');
      });

      // 5. Subscribe to universal fellowship broadcast topic
      try {
        await _fcm.subscribeToTopic('all_fellowship');
        debugPrint('Subscribed to FCM topic: all_fellowship');
      } catch (e) {
        debugPrint('FCM topic subscription notice: $e');
      }

      // 6. Setup Foreground Message listener
      _foregroundSubscription?.cancel();
      _foregroundSubscription = FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('FCM Foreground message: ${message.notification?.title} - ${message.notification?.body}');
        if (this.onForegroundMessageReceived != null) {
          this.onForegroundMessageReceived!(message);
        }
      });

      // 7. Setup Background to Foreground Tap listener
      _openedAppSubscription?.cancel();
      _openedAppSubscription = FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('FCM App opened from notification: ${message.data}');
        if (this.onNotificationOpened != null) {
          this.onNotificationOpened!(message);
        }
      });

      // 8. Check if app was launched from a terminated state notification tap
      final initialMessage = await _fcm.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('FCM App launched from terminated state via message: ${initialMessage.messageId}');
        if (this.onNotificationOpened != null) {
          this.onNotificationOpened!(initialMessage);
        }
      }
    } catch (e) {
      debugPrint('NotificationService initialize error: $e');
    }
  }

  /// Syncs the current user's FCM token and topic subscriptions in Firestore.
  /// Should be called whenever a student/admin authenticates or updates their profile.
  Future<void> syncUserFcmToken({
    required String userId,
    required String role,
    String? assignedFamilyId,
    String? departmentId,
  }) async {
    if (userId.isEmpty) return;

    try {
      final token = _currentToken ?? await _fcm.getToken();
      if (token != null && token.isNotEmpty) {
        _currentToken = token;

        // Save token to Firestore user document for targeted admin push notifications
        await _firestore.collection('users').doc(userId).set({
          'fcmToken': token,
          'fcmTokens': FieldValue.arrayUnion([token]),
          'fcmPlatform': defaultTargetPlatform.name,
          'lastTokenUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        debugPrint('Synced FCM token to Firestore for user: $userId');
      }

      // Subscribe to role-specific topics
      if (role.isNotEmpty) {
        await _fcm.subscribeToTopic('role_${role.toLowerCase()}');
      }

      // Subscribe to family topic if assigned
      if (assignedFamilyId != null && assignedFamilyId.isNotEmpty) {
        await _fcm.subscribeToTopic('family_${assignedFamilyId.replaceAll(' ', '_')}');
      }

      // Subscribe to department topic if member or coordinator
      if (departmentId != null && departmentId.isNotEmpty) {
        await _fcm.subscribeToTopic('dept_${departmentId.replaceAll(' ', '_')}');
      }
    } catch (e) {
      debugPrint('NotificationService syncUserFcmToken notice: $e');
    }
  }

  /// Unsubscribe from user-specific topics on sign out
  Future<void> clearUserSubscriptions({
    required String role,
    String? assignedFamilyId,
    String? departmentId,
  }) async {
    try {
      if (role.isNotEmpty) {
        await _fcm.unsubscribeFromTopic('role_${role.toLowerCase()}');
      }
      if (assignedFamilyId != null && assignedFamilyId.isNotEmpty) {
        await _fcm.unsubscribeFromTopic('family_${assignedFamilyId.replaceAll(' ', '_')}');
      }
      if (departmentId != null && departmentId.isNotEmpty) {
        await _fcm.unsubscribeFromTopic('dept_${departmentId.replaceAll(' ', '_')}');
      }
    } catch (e) {
      debugPrint('NotificationService clearUserSubscriptions notice: $e');
    }
  }

  /// Shows an in-app banner for foreground notifications
  static void showForegroundInAppBanner(BuildContext context, RemoteMessage message) {
    final title = message.notification?.title ?? message.data['title'] ?? 'WCU Fellowship Alert';
    final body = message.notification?.body ?? message.data['body'] ?? '';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        backgroundColor: const Color(0xFF1E293B),
        content: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFC5A059).withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_active,
                color: Color(0xFFC5A059),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                  if (body.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void dispose() {
    _foregroundSubscription?.cancel();
    _openedAppSubscription?.cancel();
    _tokenRefreshSubscription?.cancel();
  }
}
