import 'package:flutter/material.dart';
import '../../models/app_models.dart';
import '../../state/fellowship_state.dart';
import '../../theme/app_theme.dart';

class StudentMentorshipScreen extends StatefulWidget {
  final FellowshipState state;

  const StudentMentorshipScreen({super.key, required this.state});

  @override
  State<StudentMentorshipScreen> createState() => _StudentMentorshipScreenState();
}

class _StudentMentorshipScreenState extends State<StudentMentorshipScreen> {
  int _activeTab = 0; // 0: Browse Department Mentors, 1: My Mentorship Match
  String _selectedDeptFilter = 'All Departments';

  final List<String> _departments = [
    'All Departments',
    'Computer Science',
    'Medicine & Health Sciences',
    'Civil Engineering',
    'Accounting & Finance',
  ];

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Academic Mentorship • አካዳሚክ ማማከር'),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Segmented Navigation Header
          Builder(builder: (context) {
            final isSenior = state.currentUser.academicYear >= 3 || state.incomingMentorshipRequests.isNotEmpty;
            final pendingIncomingCount = state.incomingMentorshipRequests.where((r) => r.status == MentorshipStatus.pending).length;

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: theme.cardTheme.color ?? theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildNavTab(
                      context: context,
                      title: 'Senior Mentors',
                      icon: Icons.school_outlined,
                      index: 0,
                    ),
                  ),
                  Expanded(
                    child: _buildNavTab(
                      context: context,
                      title: 'My Matches (${state.myMentorshipRequests.length})',
                      icon: Icons.people_alt_outlined,
                      index: 1,
                    ),
                  ),
                  if (isSenior)
                    Expanded(
                      child: _buildNavTab(
                        context: context,
                        title: 'Incoming ($pendingIncomingCount)',
                        icon: Icons.inbox_outlined,
                        index: 2,
                      ),
                    ),
                ],
              ),
            );
          }),

          Expanded(
            child: _activeTab == 0
                ? _buildMentorsTab(context, state)
                : (_activeTab == 1 ? _buildMyMatchesTab(context, state) : _buildIncomingRequestsTab(context, state)),
          ),
        ],
      ),
    );
  }

  Widget _buildNavTab({required BuildContext context, required String title, required IconData icon, required int index}) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final isSelected = _activeTab == index;

    return GestureDetector(
      onTap: () => setState(() => _activeTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: isSelected ? primaryAccent.withOpacity(0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? Border.all(color: primaryAccent.withOpacity(0.5)) : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: isSelected ? primaryAccent : (theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary)),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? primaryAccent : (theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------
  // TAB 0: BROWSE SENIOR DEPARTMENT MENTORS
  // ----------------------------------------------------
  Widget _buildMentorsTab(BuildContext context, FellowshipState state) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;

    final filteredMentors = state.academicMentors.where((m) {
      if (_selectedDeptFilter != 'All Departments' && m.department != _selectedDeptFilter) {
        return false;
      }
      return true;
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        // Intro Banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                primaryAccent.withOpacity(0.12),
                primaryAccent.withOpacity(0.04),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: primaryAccent.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.hub_outlined, color: primaryAccent, size: 28),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Department Mentorship Network',
                      style: TextStyle(fontFamily: 'serif', fontSize: 15, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Connect with senior 3rd, 4th & 5th-year fellowship fellows in your faculty for course tutoring, exam study tips, and academic coaching.',
                      style: TextStyle(fontSize: 11, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary, height: 1.3),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // Department Filter Chips Carousel
        SizedBox(
          height: 38,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _departments.length,
            itemBuilder: (context, index) {
              final dept = _departments[index];
              final isSelected = _selectedDeptFilter == dept;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  selected: isSelected,
                  label: Text(dept, style: TextStyle(fontSize: 11, color: isSelected ? primaryAccent : theme.colorScheme.onSurface)),
                  selectedColor: primaryAccent.withOpacity(0.18),
                  checkmarkColor: primaryAccent,
                  backgroundColor: theme.cardTheme.color ?? theme.colorScheme.surface,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: isSelected ? primaryAccent : theme.dividerColor)),
                  onSelected: (_) => setState(() => _selectedDeptFilter = dept),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 18),

        if (filteredMentors.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            alignment: Alignment.center,
            child: Column(
              children: [
                Icon(Icons.school_outlined, size: 48, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5)),
                const SizedBox(height: 10),
                Text('No Senior Mentors Found in $_selectedDeptFilter', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                const SizedBox(height: 4),
                Text('Senior students (Year 3+) registered in this department will appear here automatically.', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary)),
              ],
            ),
          )
        else
          ...filteredMentors.map((mentor) {
            final isRequested = state.myMentorshipRequests.any((r) => r.mentorId == mentor.id);

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: theme.cardTheme.color ?? theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: primaryAccent.withOpacity(0.15),
                        child: Icon(Icons.school, color: primaryAccent, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              mentor.fullName,
                              style: TextStyle(
                                fontFamily: 'serif',
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'B.N. ${mentor.baptismalName} • Year ${mentor.academicYear}',
                              style: TextStyle(fontSize: 12, color: primaryAccent, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              mentor.department,
                              style: TextStyle(fontSize: 11, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Text('Specialties & Tutoring Focus:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: mentor.specialties.map((spec) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(spec, style: TextStyle(fontSize: 10, color: primaryAccent, fontWeight: FontWeight.w600)),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 14),
                  Divider(color: theme.dividerColor),
                  const SizedBox(height: 10),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          '${mentor.activeMenteesCount}/${mentor.maxMentees} Mentees Active',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: isRequested
                            ? null
                            : () => _openRequestMentorshipDialog(context, mentor),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryAccent,
                          foregroundColor: isDark ? Colors.black : Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        ),
                        child: Text(
                          isRequested ? 'Requested • ተልኳል' : 'Request Mentor • ጠይቅ',
                          style: TextStyle(
                            color: isRequested ? (theme.textTheme.bodyMedium?.color?.withOpacity(0.6) ?? AppTheme.textTertiary) : (isDark ? Colors.black : Colors.white),
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  // ----------------------------------------------------
  // TAB 1: MY MENTORSHIP MATCHES (JUNIOR VIEW)
  // ----------------------------------------------------
  Widget _buildMyMatchesTab(BuildContext context, FellowshipState state) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;
    final requests = state.myMentorshipRequests;

    if (requests.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.school_outlined, size: 60, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6) ?? AppTheme.textTertiary),
              const SizedBox(height: 16),
              Text('No Mentorship Matches Yet', style: TextStyle(fontFamily: 'serif', fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
              const SizedBox(height: 8),
              Text('Request mentorship from senior students in your department above.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary)),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: () => setState(() => _activeTab = 0),
                style: ElevatedButton.styleFrom(backgroundColor: primaryAccent, foregroundColor: isDark ? Colors.black : Colors.white),
                child: const Text('Browse Senior Mentors', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(18),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final req = requests[index];
        final isMatched = req.status == MentorshipStatus.matched;
        final isPending = req.status == MentorshipStatus.pending;
        final mentorPhone = req.mentorPhone ?? '';
        final rawTelegram = req.mentorTelegram ?? '';
        final telegramUrl = rawTelegram.startsWith('http')
            ? rawTelegram
            : 'https://t.me/${rawTelegram.replaceAll('@', '')}';

        Color statusColor;
        String statusLabel;
        if (isMatched) {
          statusColor = const Color(0xFF10B981);
          statusLabel = 'Active Match • ተቀብሏል';
        } else if (req.status == MentorshipStatus.declined) {
          statusColor = AppTheme.crimson;
          statusLabel = 'Declined • ውድቅ ተደርጓል';
        } else {
          statusColor = const Color(0xFFF59E0B);
          statusLabel = 'Pending Senior Approval • በመጠባበቅ ላይ';
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: theme.cardTheme.color ?? theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: statusColor.withOpacity(0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Mentor: ${req.mentorName}',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: statusColor.withOpacity(0.5)),
                    ),
                    child: Text(statusLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Department: ${req.department}',
                style: TextStyle(fontSize: 12, color: primaryAccent),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                'Topics: ${req.coursesNeeded}',
                style: TextStyle(fontSize: 11, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),

              if (isMatched) ...[
                if (mentorPhone.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.phone, size: 14, color: Color(0xFF10B981)),
                        const SizedBox(width: 6),
                        Text(
                          'Mentor Phone: $mentorPhone',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                Row(
                  children: [
                    if (rawTelegram.isNotEmpty) ...[
                      Flexible(
                        child: ElevatedButton.icon(
                          onPressed: () => state.launchTelegram(telegramUrl),
                          icon: const Icon(Icons.send, size: 14, color: Colors.white),
                          label: const Text('Telegram', style: TextStyle(fontSize: 11, color: Colors.white), overflow: TextOverflow.ellipsis),
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0088CC)),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (mentorPhone.isNotEmpty) ...[
                      ElevatedButton.icon(
                        icon: const Icon(Icons.phone, color: Colors.white, size: 14),
                        label: const Text('Call Senior', style: TextStyle(fontSize: 11, color: Colors.white)),
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
                        onPressed: () => state.launchCall(mentorPhone),
                      ),
                    ],
                  ],
                ),
              ] else if (isPending) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.hourglass_top, size: 16, color: Color(0xFFF59E0B)),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Mentorship request is awaiting approval from the senior student. Contact numbers and Telegram will be unlocked immediately upon acceptance.',
                          style: TextStyle(fontSize: 11, color: Color(0xFFF59E0B), height: 1.3),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  // ----------------------------------------------------
  // TAB 2: INCOMING MENTORSHIP REQUESTS (SENIOR VIEW)
  // ----------------------------------------------------
  Widget _buildIncomingRequestsTab(BuildContext context, FellowshipState state) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final requests = state.incomingMentorshipRequests;

    if (requests.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inbox_outlined, size: 54, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5)),
              const SizedBox(height: 14),
              Text('No Incoming Mentorship Requests', style: TextStyle(fontFamily: 'serif', fontSize: 16, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
              const SizedBox(height: 6),
              Text('When junior students request mentorship from you, they will appear here.', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary)),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(18),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final req = requests[index];
        final isPending = req.status == MentorshipStatus.pending;
        final isMatched = req.status == MentorshipStatus.matched;

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: theme.cardTheme.color ?? theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isMatched ? const Color(0xFF10B981) : primaryAccent.withOpacity(0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Student: ${req.juniorName} (${req.juniorBaptismalName})',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isMatched ? const Color(0xFF10B981).withOpacity(0.2) : const Color(0xFFF59E0B).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isMatched ? 'Accepted • ተቀብለዋል' : (isPending ? 'Pending Review' : 'Declined'),
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isMatched ? const Color(0xFF10B981) : const Color(0xFFF59E0B)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Dept: ${req.department} • Year ${req.academicYear}',
                style: TextStyle(fontSize: 11, color: primaryAccent, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                'Needs Help With: ${req.coursesNeeded}',
                style: TextStyle(fontSize: 11, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary),
              ),
              if (req.juniorPhone != null && req.juniorPhone!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  'Student Phone: ${req.juniorPhone}',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                ),
              ],
              const SizedBox(height: 14),

              if (isPending) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => state.updateMentorshipStatus(req.id, MentorshipStatus.declined),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.crimson,
                        side: const BorderSide(color: AppTheme.crimson),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Decline / ውድቅ አድርግ', style: TextStyle(fontSize: 11)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        state.updateMentorshipStatus(req.id, MentorshipStatus.matched);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Accepted mentorship for ${req.juniorName}!')),
                        );
                      },
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Accept & Share Contact / ተቀበል', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ] else if (isMatched && req.juniorPhone != null && req.juniorPhone!.isNotEmpty) ...[
                ElevatedButton.icon(
                  onPressed: () => state.launchCall(req.juniorPhone!),
                  icon: const Icon(Icons.phone, size: 14, color: Colors.white),
                  label: Text('Call Student (${req.juniorPhone})', style: const TextStyle(fontSize: 11, color: Colors.white)),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _openRequestMentorshipDialog(BuildContext context, AcademicMentorModel mentor) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;
    final coursesController = TextEditingController(text: mentor.specialties.first);

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: theme.cardTheme.color ?? theme.colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Request Mentorship with ${mentor.fullName}', style: TextStyle(fontFamily: 'serif', fontSize: 16, color: primaryAccent, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Department: ${mentor.department}', style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary)),
              const SizedBox(height: 12),
              TextField(
                controller: coursesController,
                decoration: const InputDecoration(
                  labelText: 'Courses / Topics You Need Help With',
                  hintText: 'e.g. Data Structures, Exam Study Plan',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: TextStyle(color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary))),
            ElevatedButton(
              onPressed: () {
                widget.state.requestMentorship(
                  mentorId: mentor.id,
                  coursesNeeded: coursesController.text.trim(),
                );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Mentorship request sent to ${mentor.fullName}'), backgroundColor: theme.cardTheme.color ?? theme.colorScheme.surface),
                );
                setState(() => _activeTab = 1);
              },
              style: ElevatedButton.styleFrom(backgroundColor: primaryAccent),
              child: Text('Send Request', style: TextStyle(color: isDark ? Colors.black : Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}
