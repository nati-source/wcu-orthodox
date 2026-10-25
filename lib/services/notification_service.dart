import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/program_models.dart';

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

  /// Global navigator context accessor for displaying notifications anywhere in the app
  static BuildContext? Function()? globalContextProvider;

  FirebaseMessaging get _fcm => FirebaseMessaging.instance;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  bool _localNotificationsInitialized = false;

  static const AndroidNotificationChannel _reminderChannel = AndroidNotificationChannel(
    'liturgy_fellowship_reminders',
    'Liturgy & Fellowship Reminders',
    description: 'Notifications and reminders for Holy Liturgy and Church Programs.',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

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
      tz.initializeTimeZones();
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

      // 9. Initialize local notifications plugin for system-level screen popups
      try {
        const AndroidInitializationSettings androidSettings =
            AndroidInitializationSettings('@mipmap/ic_launcher');
        const InitializationSettings initSettings =
            InitializationSettings(android: androidSettings);

        await _localNotifications.initialize(
          settings: initSettings,
          onDidReceiveNotificationResponse: (NotificationResponse response) {
            debugPrint('Local notification clicked: ${response.payload}');
          },
        );

        final androidImpl = _localNotifications
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        if (androidImpl != null) {
          await androidImpl.createNotificationChannel(_reminderChannel);
          await androidImpl.requestNotificationsPermission();
        }
        _localNotificationsInitialized = true;
        debugPrint('FlutterLocalNotificationsPlugin initialized successfully.');
      } catch (e) {
        debugPrint('FlutterLocalNotificationsPlugin init error: $e');
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

    final topicNames = <String>{};
    if (role.isNotEmpty) topicNames.add('role_${role.toLowerCase()}');
    if (assignedFamilyId != null && assignedFamilyId.isNotEmpty) {
      topicNames.add('family_${assignedFamilyId.replaceAll(' ', '_')}');
    }
    if (departmentId != null && departmentId.isNotEmpty) {
      topicNames.add('dept_${departmentId.replaceAll(' ', '_')}');
    }

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
    } catch (e) {
      debugPrint('NotificationService token persistence notice: $e');
    }

    for (final topic in topicNames) {
      try {
        await _fcm.subscribeToTopic(topic);
      } catch (e) {
        debugPrint('NotificationService subscription to $topic failed: $e');
      }
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

  /// Displays an immediate high-priority in-app alert banner with haptic feedback
  static void showLocalInAppNotification({
    BuildContext? context,
    required String title,
    required String body,
    String badgeLabel = 'FELLOWSHIP ALERT • ማስታወሻ',
    IconData icon = Icons.notifications_active,
    Color iconColor = const Color(0xFFC5A059),
    Duration duration = const Duration(seconds: 6),
  }) {
    final ctx = context ?? globalContextProvider?.call();
    if (ctx == null) return;

    try {
      HapticFeedback.heavyImpact();
    } catch (_) {}

    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: const Color(0xFF0F172A),
        elevation: 8,
        content: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(color: iconColor.withOpacity(0.4)),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          badgeLabel,
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
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
                        height: 1.3,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        duration: duration,
      ),
    );
  }

  /// Displays an immediate system-level heads-up notification that pops up on screen
  /// even when the user is outside the app or on the home screen.
  Future<void> showSystemNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      if (!_localNotificationsInitialized) {
        const AndroidInitializationSettings androidSettings =
            AndroidInitializationSettings('@mipmap/ic_launcher');
        await _localNotifications.initialize(
          settings: const InitializationSettings(android: androidSettings),
        );
        final androidImpl = _localNotifications
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        await androidImpl?.createNotificationChannel(_reminderChannel);
        _localNotificationsInitialized = true;
      }

      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        _reminderChannel.id,
        _reminderChannel.name,
        channelDescription: _reminderChannel.description,
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'WCU Orthodox Reminder',
        playSound: true,
        enableVibration: true,
        icon: '@mipmap/ic_launcher',
        styleInformation: BigTextStyleInformation(body),
      );

      final NotificationDetails details = NotificationDetails(android: androidDetails);
      await _localNotifications.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: details,
        payload: payload,
      );
    } catch (e) {
      debugPrint('Error showing system notification: $e');
    }
  }

  /// Cancels an active system notification by ID
  Future<void> cancelNotification(int id) async {
    try {
      await _localNotifications.cancel(id: id);
    } catch (e) {
      debugPrint('Error cancelling notification: $e');
    }
  }

  final Map<String, DateTime> _scheduledProgramDates = {};

  static int _getNotificationId(String programId, int offsetMinutes) {
    final base = (programId.hashCode & 0x7FFFFFFF) % 100000;
    final offsetIndex = switch (offsetMinutes) {
      60 => 1,
      30 => 2,
      15 => 3,
      7 => 4,
      _ => 0,
    };
    return base * 10 + offsetIndex;
  }

  /// Cancels all scheduled notification thresholds for a specific program
  Future<void> cancelProgramNotifications(String programId) async {
    _scheduledProgramDates.remove(programId);
    for (final offset in [60, 30, 15, 7, 0]) {
      await cancelNotification(_getNotificationId(programId, offset));
    }
  }

  /// Synchronizes scheduled background alarms/notifications for upcoming church programs.
  /// Tracks a signature map so unchanged programs are not redundantly rescheduled.
  Future<void> syncScheduledProgramNotifications(
    List<ChurchProgramModel> programs, {
    bool masterReminderEnabled = true,
  }) async {
    if (!masterReminderEnabled) {
      final scheduledIds = List<String>.from(_scheduledProgramDates.keys);
      for (final id in scheduledIds) {
        await cancelProgramNotifications(id);
      }
      _scheduledProgramDates.clear();
      return;
    }

    final programsSnapshot = List<ChurchProgramModel>.from(programs);
    final now = DateTime.now();
    final activeIds = programsSnapshot
        .where((p) => p.reminderEnabled && !p.isEmergency && p.dateTime.isAfter(now))
        .map((p) => p.id)
        .toSet();

    // Cancel notifications for any removed or disabled programs
    final removedIds = _scheduledProgramDates.keys.where((id) => !activeIds.contains(id)).toList();
    for (final id in removedIds) {
      await cancelProgramNotifications(id);
    }

    for (final program in programsSnapshot) {
      if (!program.reminderEnabled || program.isEmergency) {
        if (_scheduledProgramDates.containsKey(program.id)) {
          await cancelProgramNotifications(program.id);
        }
        continue;
      }

      final programTime = program.dateTime;
      if (!programTime.isAfter(now)) {
        if (_scheduledProgramDates.containsKey(program.id)) {
          await cancelProgramNotifications(program.id);
        }
        continue;
      }

      // Check if unchanged to avoid redundant rescheduling
      if (_scheduledProgramDates[program.id] == programTime) {
        continue;
      }

      // Cancel prior notifications for this program before rescheduling
      if (_scheduledProgramDates.containsKey(program.id)) {
        await cancelProgramNotifications(program.id);
      }

      final thresholds = [
        (60, '🔔 60 Minutes Remaining • 1 ሰዓት ቀርቷል', '"${program.title}" በ ${program.churchName} በ1 ሰዓት ውስጥ ይጀምራል።'),
        (30, '🔔 30 Minutes Remaining • 30 ደቂቃ ቀርቷል', '"${program.title}" በ ${program.churchName} በ30 ደቂቃ ውስጥ ይጀምራል።'),
        (15, '🔔 15 Minutes Remaining • 15 ደቂቃ ቀርቷል', '"${program.title}" በ ${program.churchName} በ15 ደቂቃ ውስጥ ይጀምራል።'),
        (7, '🔔 7 Minutes Remaining • ጥቂት ደቂቃዎች ቀሩ', '"${program.title}" በ ${program.churchName} በ7 ደቂቃ ውስጥ ይጀምራል።'),
        (0, '🔔 የ${program.category} ሰዓት ደርሷል! (Program Started)', '"${program.title}" በ ${program.churchName} አሁን ተጀምሯል። እንኳን አደረሳችሁ!'),
      ];

      for (final item in thresholds) {
        final offset = item.$1;
        final title = item.$2;
        final body = item.$3;
        final scheduledTime = programTime.subtract(Duration(minutes: offset));
        if (scheduledTime.isAfter(now)) {
          await _scheduleLocalNotification(
            id: _getNotificationId(program.id, offset),
            title: title,
            body: body,
            scheduledDateTime: scheduledTime,
          );
        }
      }

      _scheduledProgramDates[program.id] = programTime;
    }
  }

  Future<void> _scheduleLocalNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDateTime,
  }) async {
    try {
      try {
        tz.local;
      } catch (_) {
        tz.initializeTimeZones();
      }
      final tzDateTime = tz.TZDateTime.from(scheduledDateTime, tz.local);
      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        _reminderChannel.id,
        _reminderChannel.name,
        channelDescription: _reminderChannel.description,
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'WCU Orthodox Reminder',
        playSound: true,
        enableVibration: true,
        icon: '@mipmap/ic_launcher',
        styleInformation: BigTextStyleInformation(body),
      );
      final NotificationDetails details = NotificationDetails(android: androidDetails);
      await _localNotifications.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tzDateTime,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } catch (e) {
      debugPrint('Error scheduling local notification: $e');
    }
  }

  void dispose() {
    _foregroundSubscription?.cancel();
    _openedAppSubscription?.cancel();
    _tokenRefreshSubscription?.cancel();
  }
}
