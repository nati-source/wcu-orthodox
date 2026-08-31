import 'package:flutter/material.dart';
import '../../models/app_models.dart';
import '../../state/fellowship_state.dart';
import '../../theme/app_theme.dart';

class StudentRoadmapScreen extends StatelessWidget {
  final FellowshipState state;
  final VoidCallback onOpenScanner;

  const StudentRoadmapScreen({
    super.key,
    required this.state,
    required this.onOpenScanner,
  });

  @override
  Widget build(BuildContext context) {
    final roadmaps = state.roadmaps;

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 90),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Intro Header Card matching screen1 - Copy.png
              const Text(
                'Spiritual Journey',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'serif',
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Track your progress through the fellowship\'s core curriculum. Attend sessions and participate in study to unlock deeper mysteries of the faith.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 28),

              // Interactive Timeline
              ...List.generate(roadmaps.length, (index) {
                final phase = roadmaps[index];
                final isLast = index == roadmaps.length - 1;
                return _buildTimelineItem(
                  context: context,
                  phase: phase,
                  isLast: isLast,
                );
              }),
            ],
          ),
        ),

        // Floating "Check In [QR]" Button matching screen1 - Copy.png
        Positioned(
          right: 20,
          bottom: 20,
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              gradient: const LinearGradient(
                colors: [Color(0xFFE57E12), Color(0xFFD4690B)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFD4690B).withOpacity(0.5),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: onOpenScanner,
              icon: const Icon(Icons.qr_code_scanner, color: Colors.black, size: 22),
              label: const Text(
                'Check In',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  letterSpacing: 0.3,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineItem({
    required BuildContext context,
    required RoadmapPhaseModel phase,
    required bool isLast,
  }) {
    Color indicatorColor;
    IconData indicatorIcon;

    switch (phase.status) {
      case RoadmapStatus.completed:
        indicatorColor = const Color(0xFFE57E12);
        indicatorIcon = Icons.check;
        break;
      case RoadmapStatus.inProgress:
        indicatorColor = const Color(0xFFE5A65E);
        indicatorIcon = Icons.menu_book_outlined;
        break;
      case RoadmapStatus.locked:
        indicatorColor = AppTheme.borderMuted;
        indicatorIcon = Icons.lock_outline;
        break;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline Column
          SizedBox(
            width: 48,
            child: Column(
              children: [
                // Node Circle
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.secondaryBg,
                    border: Border.all(
                      color: indicatorColor,
                      width: phase.status == RoadmapStatus.inProgress ? 2.5 : 2,
                    ),
                    boxShadow: phase.status == RoadmapStatus.inProgress
                        ? [
                            BoxShadow(
                              color: indicatorColor.withOpacity(0.4),
                              blurRadius: 10,
                              spreadRadius: 1,
                            )
                          ]
                        : null,
                  ),
                  child: Icon(indicatorIcon, color: indicatorColor, size: 18),
                ),
                // Connector Line
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: phase.status == RoadmapStatus.completed
                          ? const Color(0xFFD4690B)
                          : AppTheme.borderMuted,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),

          // Phase Card
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: InkWell(
                onTap: () => _openPhaseLessonsSheet(context, phase),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: phase.status == RoadmapStatus.inProgress
                          ? AppTheme.goldAccent.withOpacity(0.6)
                          : AppTheme.borderMuted,
                      width: phase.status == RoadmapStatus.inProgress ? 1.5 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status Header
                      Row(
                        children: [
                          if (phase.status == RoadmapStatus.completed) ...[
                            const Icon(Icons.check_circle, color: Color(0xFFE57E12), size: 16),
                            const SizedBox(width: 6),
                            const Text(
                              'COMPLETED',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFE57E12),
                                letterSpacing: 1.2,
                              ),
                            ),
                          ] else if (phase.status == RoadmapStatus.inProgress) ...[
                            const Icon(Icons.autorenew, color: Color(0xFFF5A65E), size: 16),
                            const SizedBox(width: 6),
                            const Text(
                              'IN PROGRESS',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFF5A65E),
                                letterSpacing: 1.2,
                              ),
                            ),
                          ] else ...[
                            const Icon(Icons.lock, color: AppTheme.textTertiary, size: 16),
                            const SizedBox(width: 6),
                            const Text(
                              'LOCKED',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textTertiary,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Title
                      Text(
                        phase.title,
                        style: const TextStyle(
                          fontFamily: 'serif',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Description
                      Text(
                        phase.description,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                          height: 1.4,
                        ),
                      ),

                      // Progress Bar if in progress
                      if (phase.status == RoadmapStatus.inProgress) ...[
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Progress',
                              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                            ),
                            Text(
                              '${(phase.progress * 100).toInt()}%',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFF5A65E),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: phase.progress,
                            minHeight: 6,
                            backgroundColor: AppTheme.surfaceElevated,
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFE57E12)),
                          ),
                        ),
                      ],

                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.person_pin, size: 14, color: AppTheme.textTertiary),
                          const SizedBox(width: 4),
                          Text(
                            phase.instructor,
                            style: const TextStyle(fontSize: 11, color: AppTheme.textTertiary),
                          ),
                          const Spacer(),
                          const Text(
                            'View Lessons',
                            style: TextStyle(fontSize: 12, color: AppTheme.goldLight, fontWeight: FontWeight.bold),
                          ),
                          const Icon(Icons.chevron_right, size: 16, color: AppTheme.goldLight),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openPhaseLessonsSheet(BuildContext context, RoadmapPhaseModel phase) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
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
                    phase.title,
                    style: const TextStyle(
                      fontFamily: 'serif',
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.goldLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Instructor: ${phase.instructor} • ${phase.semester}',
                    style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 10),
                  const Text(
                    'Weekly Curriculum & Reading List',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (phase.weeklyLessons.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Weekly curriculum for this phase will unlock once prerequisites are met.',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                      ),
                    )
                  else
                    ...phase.weeklyLessons.map((lesson) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.secondaryBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.borderMuted),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    lesson.title,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    lesson.isDownloaded ? Icons.download_done : Icons.download_outlined,
                                    color: lesson.isDownloaded ? AppTheme.emerald : AppTheme.goldLight,
                                  ),
                                  onPressed: () {
                                    state.toggleLessonDownload(phase.id, lesson.id);
                                    Navigator.pop(ctx);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(lesson.isDownloaded
                                            ? 'Lesson removed from offline cache'
                                            : 'Downloaded for offline study'),
                                        backgroundColor: AppTheme.surfaceColor,
                                      ),
                                    );
                                  },
                                  tooltip: 'Download for Offline Reading',
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              lesson.summary,
                              style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.4),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Required Readings:',
                              style: TextStyle(fontSize: 12, color: AppTheme.goldLight, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            ...lesson.readingList.map((reading) => Padding(
                                  padding: const EdgeInsets.only(left: 4, bottom: 2),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.circle, size: 6, color: AppTheme.textTertiary),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          reading,
                                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                        ),
                                      ),
                                    ],
                                  ),
                                )),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
