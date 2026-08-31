import 'package:flutter/material.dart';
import '../../models/app_models.dart';
import '../../state/fellowship_state.dart';
import '../../theme/app_theme.dart';

class StudentMinistryScreen extends StatelessWidget {
  final FellowshipState state;

  const StudentMinistryScreen({super.key, required this.state});

  IconData _getMinistryIcon(String iconName) {
    switch (iconName) {
      case 'music_note':
        return Icons.music_note;
      case 'volunteer_activism':
        return Icons.volunteer_activism;
      case 'handshake':
        return Icons.handshake;
      case 'camera_alt':
        return Icons.camera_alt;
      case 'church':
        return Icons.church;
      default:
        return Icons.group_work;
    }
  }

  void _openApplicationDialog(BuildContext context, MinistryModel ministry) {
    final reasonController = TextEditingController();
    final experienceController = TextEditingController();
    final availabilityController = TextEditingController(text: 'Weekends & Friday evenings');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            top: 20,
            left: 20,
            right: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.borderMuted,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Apply: ${ministry.title}',
                  style: const TextStyle(
                    fontFamily: 'serif',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.goldLight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Team Lead: ${ministry.teamLead} • ${ministry.openSlots} open slots',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 16),

                // Reason for applying
                const Text('Why do you want to serve in this ministry?',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(
                  controller: reasonController,
                  maxLines: 2,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: const InputDecoration(
                    hintText: 'Share your spiritual calling or motivation...',
                  ),
                ),
                const SizedBox(height: 12),

                // Experience / skills
                const Text('Previous Experience or Skills',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(
                  controller: experienceController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: const InputDecoration(
                    hintText: 'e.g. 2 years parish choir, sound engineering, hospitality...',
                  ),
                ),
                const SizedBox(height: 12),

                // Availability
                const Text('Your Availability',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(
                  controller: availabilityController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: const InputDecoration(
                    hintText: 'e.g. Saturdays, Sundays after Kidase',
                  ),
                ),
                const SizedBox(height: 20),

                // Submit Button
                ElevatedButton(
                  onPressed: () {
                    if (reasonController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter your reason for applying')),
                      );
                      return;
                    }
                    state.submitMinistryApplication(
                      ministryId: ministry.id,
                      reason: reasonController.text.trim(),
                      experience: experienceController.text.trim(),
                      availability: availabilityController.text.trim(),
                    );
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Application for ${ministry.title} submitted! Awaiting coordinator review.'),
                        backgroundColor: AppTheme.surfaceColor,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4690B),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Submit Application', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ministries = state.ministries;
    final myApplications = state.volunteerApplications.where((a) => a.studentId == state.currentUser.id).toList();

    return Scaffold(
      backgroundColor: AppTheme.primaryBg,
      appBar: AppBar(
        title: const Text('Voluntary Serving Areas'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.goldLight),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Description
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.secondaryBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.borderMuted),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Serve with Joy & Dedication',
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.goldLight,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Explore the various fellowship wings at Wachamo University. Every member has unique talents given by God to build up the body of Christ.',
                    style: TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.4),
                  ),
                ],
              ),
            ),

            if (myApplications.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text(
                'My Active Applications',
                style: TextStyle(
                  fontFamily: 'serif',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              ...myApplications.map((app) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: app.status == ApplicationStatus.approved
                          ? AppTheme.emerald
                          : app.status == ApplicationStatus.rejected
                              ? AppTheme.crimson
                              : AppTheme.amberGlow,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        app.status == ApplicationStatus.approved
                            ? Icons.check_circle
                            : app.status == ApplicationStatus.rejected
                                ? Icons.cancel
                                : Icons.hourglass_top,
                        color: app.status == ApplicationStatus.approved
                            ? AppTheme.emerald
                            : app.status == ApplicationStatus.rejected
                                ? AppTheme.crimson
                                : AppTheme.amberGlow,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              app.ministryTitle,
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Availability: ${app.availability}',
                              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceElevated,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          app.status.name.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: app.status == ApplicationStatus.approved
                                ? AppTheme.emerald
                                : app.status == ApplicationStatus.rejected
                                    ? AppTheme.crimson
                                    : AppTheme.amberGlow,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],

            const SizedBox(height: 24),
            const Text(
              'Open Fellowship Ministries',
              style: TextStyle(
                fontFamily: 'serif',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),

            ...ministries.map((min) {
              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.borderMuted),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.goldAccent.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(_getMinistryIcon(min.iconName), color: AppTheme.goldLight, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                min.title,
                                style: const TextStyle(
                                  fontFamily: 'serif',
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Lead: ${min.teamLead} • ${min.activeCount} active members',
                                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      min.description,
                      style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.4),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF222B3A),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${min.openSlots} Open Slots',
                            style: const TextStyle(fontSize: 11, color: AppTheme.goldLight, fontWeight: FontWeight.w600),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () => _openApplicationDialog(context, min),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD4690B),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Apply Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
