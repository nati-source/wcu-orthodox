import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../models/app_models.dart';
import '../../theme/app_theme.dart';

/// Shown to students who have registered but whose account has not yet
/// been approved by the fellowship admin.
class PendingApprovalScreen extends StatefulWidget {
  final String? fullName;
  final String? email;
  final VoidCallback? onCheckStatus;

  const PendingApprovalScreen({
    super.key,
    this.fullName,
    this.email,
    this.onCheckStatus,
  });

  @override
  State<PendingApprovalScreen> createState() => _PendingApprovalScreenState();
}

class _PendingApprovalScreenState extends State<PendingApprovalScreen> {
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    if (AppAdminConstants.isAdminEmail(widget.email)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _autoUnlockAdmin();
      });
    }
  }

  Future<void> _autoUnlockAdmin() async {
    setState(() => _isChecking = true);
    try {
      final user = AuthService().currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'id': user.uid,
          'email': AppAdminConstants.adminEmail,
          'role': 'admin',
          'isApproved': true,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (_) {}
    if (mounted) {
      setState(() => _isChecking = false);
      if (widget.onCheckStatus != null) {
        widget.onCheckStatus!();
      }
    }
  }

  Future<void> _checkStatus() async {
    if (AppAdminConstants.isAdminEmail(widget.email)) {
      await _autoUnlockAdmin();
      return;
    }
    setState(() => _isChecking = true);
    if (widget.onCheckStatus != null) {
      widget.onCheckStatus!();
    }
    await Future.delayed(const Duration(milliseconds: 1200));
    if (mounted) {
      setState(() => _isChecking = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.hourglass_top_rounded, color: AppTheme.gold, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Your registration is still awaiting admin review. Once approved, access is granted automatically.',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          backgroundColor: AppTheme.surfaceElevated,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: AppTheme.primaryBg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Church icon
                  Container(
                    width: 88,
                    height: 88,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppTheme.goldGradient,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.gold.withOpacity(0.35),
                          blurRadius: 28,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.church_rounded,
                        size: 48,
                        color: Color(0xFF070F1E),
                      ),
                    ),
                  ),

                  // Title
                  const Text(
                    'Registration Submitted!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'ምዝገባዎ ተቀብሏል — ጸድቆ ይጠብቁ',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.gold,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Status card
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceElevated,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.gold.withOpacity(0.35)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Pending badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B).withOpacity(0.18),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.6)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.hourglass_top_rounded, color: Color(0xFFF59E0B), size: 16),
                              SizedBox(width: 6),
                              Text(
                                'Awaiting Admin Approval',
                                style: TextStyle(
                                  color: Color(0xFFF59E0B),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),

                        if (widget.fullName != null && widget.fullName!.isNotEmpty) ...[
                          _buildInfoRow(Icons.person_outline, 'Name', widget.fullName!),
                          const SizedBox(height: 10),
                        ],
                        if (widget.email != null && widget.email!.isNotEmpty) ...[
                          _buildInfoRow(Icons.email_outlined, 'Email', widget.email!),
                          const SizedBox(height: 10),
                        ],

                        const Divider(color: AppTheme.borderMuted, height: 24),

                        const Text(
                          'Your registration has been received by the WCU Orthodox Fellowship. The fellowship admin will review and approve your account.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                            height: 1.55,
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Steps
                        _buildStep('1', 'Registration submitted to admin queue'),
                        const SizedBox(height: 8),
                        _buildStep('2', 'Admin reviews and approves your account'),
                        const SizedBox(height: 8),
                        _buildStep('3', 'You gain full access to fellowship services'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Live status hint
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.azure.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.azure.withOpacity(0.35)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.bolt_rounded, color: AppTheme.azure, size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Real-time sync active: As soon as the fellowship admin accepts your registration, your app will automatically unlock.',
                            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (AppAdminConstants.isAdminEmail(widget.email)) ...[
                    ElevatedButton.icon(
                      onPressed: _isChecking ? null : _autoUnlockAdmin,
                      icon: const Icon(Icons.admin_panel_settings_rounded, size: 20),
                      label: const Text(
                        'Unlock Admin Access • እንደ አድሚን ይግቡ',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.emerald,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Check Status Button
                  ElevatedButton.icon(
                    onPressed: _isChecking ? null : _checkStatus,
                    icon: _isChecking
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF070F1E)))
                        : const Icon(Icons.refresh_rounded, size: 20),
                    label: Text(
                      _isChecking ? 'Checking status...' : 'Check Approval Status / ሁኔታውን አረጋግጥ',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.gold,
                      foregroundColor: const Color(0xFF070F1E),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Sign out
                  OutlinedButton.icon(
                    onPressed: () async {
                      await AuthService().signOut();
                    },
                    icon: const Icon(Icons.logout, size: 18, color: AppTheme.slateMuted),
                    label: const Text(
                      'Sign Out / ወጣ',
                      style: TextStyle(color: AppTheme.slateMuted, fontSize: 14),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: AppTheme.borderMuted),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.gold, size: 18),
        const SizedBox(width: 10),
        Text(
          '$label: ',
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildStep(String number, String description) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: AppTheme.gold.withOpacity(0.15),
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.gold.withOpacity(0.5)),
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: AppTheme.gold,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            description,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.4),
          ),
        ),
      ],
    );
  }
}
