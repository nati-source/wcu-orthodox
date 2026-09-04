import 'package:flutter/material.dart';
import '../../models/app_models.dart';
import '../../state/fellowship_state.dart';
import '../../theme/app_theme.dart';

class StudentMinistryScreen extends StatefulWidget {
  final FellowshipState state;

  const StudentMinistryScreen({super.key, required this.state});

  @override
  State<StudentMinistryScreen> createState() => _StudentMinistryScreenState();
}

class _StudentMinistryScreenState extends State<StudentMinistryScreen> {
  MinistryPillar? _selectedPillar; // null means 'All'
  String _searchQuery = '';

  IconData _getMinistryIcon(String iconName) {
    switch (iconName) {
      case 'menu_book':
        return Icons.menu_book;
      case 'favorite_border':
        return Icons.favorite_border;
      case 'music_note':
        return Icons.music_note;
      case 'monetization_on_outlined':
        return Icons.monetization_on_outlined;
      case 'account_balance_wallet':
        return Icons.account_balance_wallet;
      case 'event_available':
        return Icons.event_available;
      case 'volunteer_activism':
        return Icons.volunteer_activism;
      case 'translate':
        return Icons.translate;
      case 'insights':
        return Icons.insights;
      case 'fact_check_outlined':
        return Icons.fact_check_outlined;
      default:
        return Icons.group_work;
    }
  }

  void _openApplicationDialog(BuildContext context, MinistryModel ministry) {
    final state = widget.state;
    String selectedSubWing = ministry.subWings.isNotEmpty ? ministry.subWings.first : 'General Serving';
    String selectedYear = '2nd Year';
    final reasonController = TextEditingController();
    final experienceController = TextEditingController();
    final availabilityController = TextEditingController(text: 'Weekends & weekday evenings');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
                top: 16,
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
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppTheme.borderMuted,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Header with Bilingual Title
                    Text(
                      ministry.titleAmharic,
                      style: const TextStyle(
                        fontFamily: 'serif',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.goldLight,
                      ),
                    ),
                    Text(
                      'Apply to ${ministry.titleEn}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Coordinator Info Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceElevated,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.goldAccent.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.person_pin, color: Color(0xFFF5A65E), size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Reviewed by ${ministry.teamLead} (${ministry.coordinatorRole})',
                              style: const TextStyle(fontSize: 11, color: Color(0xFFF5A65E), fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Preferred Sub-wing Dropdown
                    const Text('Select Specific Sub-wing (የአገልግሎት ዘርፍ)',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.borderMuted),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedSubWing,
                          isExpanded: true,
                          dropdownColor: AppTheme.surfaceElevated,
                          style: const TextStyle(fontSize: 12, color: Colors.white),
                          items: ministry.subWings.map((wing) {
                            return DropdownMenuItem(value: wing, child: Text(wing, style: const TextStyle(fontSize: 12)));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setModalState(() => selectedSubWing = val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Academic Year / Batch Dropdown
                    const Text('Your Academic Year / Batch (የትምህርት ክፍለ ዓመት)',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.borderMuted),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedYear,
                          isExpanded: true,
                          dropdownColor: AppTheme.surfaceElevated,
                          style: const TextStyle(fontSize: 12, color: Colors.white),
                          items: ['1st Year Freshman', '2nd Year', '3rd Year', '4th Year Graduating', 'Postgraduate']
                              .map((yr) => DropdownMenuItem(value: yr, child: Text(yr, style: const TextStyle(fontSize: 12))))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) setModalState(() => selectedYear = val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Reason for applying
                    const Text('Spiritual Calling & Motivation (የአገልግሎት ፍላጎትህ/ሽ)',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: reasonController,
                      maxLines: 2,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: const InputDecoration(
                        hintText: 'Why do you feel called to serve in this department?',
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Experience / skills
                    const Text('Church Background & Skills (ልምድ ወይም ክህሎት)',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: experienceController,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: const InputDecoration(
                        hintText: 'e.g. Parish choir, Begena learner, high school tutoring, Red Cross...',
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Availability
                    const Text('Weekly Availability (የአገልግሎት ሰዓት)',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: availabilityController,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: const InputDecoration(
                        hintText: 'e.g. Saturdays, Sunday afternoons, free evenings...',
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Submit Button
                    ElevatedButton.icon(
                      onPressed: () {
                        if (reasonController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please share your motivation for serving')),
                          );
                          return;
                        }
                        state.submitMinistryApplication(
                          ministryId: ministry.id,
                          reason: reasonController.text.trim(),
                          experience: experienceController.text.trim().isNotEmpty
                              ? experienceController.text.trim()
                              : 'Ready to be trained',
                          availability: availabilityController.text.trim(),
                          studentYear: selectedYear,
                          preferredSubWing: selectedSubWing,
                        );
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Application routed directly to ${ministry.teamLead} (${ministry.titleAmharic})!'),
                            backgroundColor: AppTheme.surfaceColor,
                          ),
                        );
                      },
                      icon: const Icon(Icons.send, size: 16, color: Colors.black),
                      label: const Text(
                        'Submit Application to Coordinator',
                        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF5A65E),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final allMinistries = state.ministries;

    // Filter by Pillar and Search Query
    final filteredMinistries = allMinistries.where((m) {
      final matchesPillar = _selectedPillar == null || m.pillar == _selectedPillar;
      final query = _searchQuery.toLowerCase().trim();
      final matchesQuery = query.isEmpty ||
          m.titleEn.toLowerCase().contains(query) ||
          m.titleAmharic.toLowerCase().contains(query) ||
          m.descriptionEn.toLowerCase().contains(query) ||
          m.descriptionAmharic.toLowerCase().contains(query) ||
          m.teamLead.toLowerCase().contains(query) ||
          m.subWings.any((w) => w.toLowerCase().contains(query));
      return matchesPillar && matchesQuery;
    }).toList();

    final myApplications = state.volunteerApplications
        .where((a) => a.studentId == state.currentUser.id)
        .toList();

    return Scaffold(
      backgroundColor: AppTheme.primaryBg,
      appBar: AppBar(
        title: const Text('Voluntary Serving • ንዑሳን ክፍሎች'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.goldLight),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Hero Introduction Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2C364A), Color(0xFF17202E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.goldAccent.withOpacity(0.35)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.goldAccent.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.church_outlined, color: AppTheme.goldLight, size: 22),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '10 EOTC Campus Sub-Committees',
                              style: TextStyle(
                                fontFamily: 'serif',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'የግቢ ጉባኤ 10ሩ ንዑሳን የአገልግሎት ክፍላት',
                              style: TextStyle(fontSize: 12, color: Color(0xFFF5A65E)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Every member is gifted to serve. Applications are reviewed directly by the respective Department Coordinator for rapid screening and onboarding.',
                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.35),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 2. Search Box
            TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Search by department, coordinator, or sub-wing...',
                prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary, size: 18),
                filled: true,
                fillColor: AppTheme.secondaryBg,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppTheme.borderMuted),
                ),
              ),
            ),

            const SizedBox(height: 14),

            // 3. 4-Pillar Filter Tabs
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildPillarFilterChip(null, 'All 10 Wings (ሁሉንም)', allMinistries.length),
                  ...MinistryPillar.values.map((pillar) {
                    final count = allMinistries.where((m) => m.pillar == pillar).length;
                    return _buildPillarFilterChip(pillar, pillar.shortName, count);
                  }),
                ],
              ),
            ),

            // 4. My Active Applications Status (if any)
            if (myApplications.isNotEmpty) ...[
              const SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'My Department Applications',
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceElevated,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${myApplications.length} active',
                      style: const TextStyle(fontSize: 10, color: AppTheme.goldLight, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ...myApplications.map((app) => _buildApplicationCard(app)),
            ],

            const SizedBox(height: 22),

            // 5. Section Title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Explore Fellowship Wings',
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '${filteredMinistries.length} Departments',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 6. Departments List
            if (filteredMinistries.isEmpty)
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.borderMuted),
                ),
                child: const Center(
                  child: Text(
                    'No departments match your filter or search query.',
                    style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                  ),
                ),
              )
            else
              ...filteredMinistries.map((min) => _buildMinistryCard(min)),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildPillarFilterChip(MinistryPillar? pillar, String label, int count) {
    final isSelected = _selectedPillar == pillar;
    return GestureDetector(
      onTap: () => setState(() => _selectedPillar = pillar),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF5A65E) : AppTheme.secondaryBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFFF5A65E) : AppTheme.borderMuted,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.black : AppTheme.textSecondary,
              ),
            ),
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected ? Colors.black.withOpacity(0.2) : AppTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.black : AppTheme.goldLight,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApplicationCard(VolunteerApplicationModel app) {
    final isApproved = app.status == ApplicationStatus.approved;
    final isRejected = app.status == ApplicationStatus.rejected;
    final statusColor = isApproved
        ? AppTheme.emerald
        : isRejected
            ? AppTheme.crimson
            : const Color(0xFFF5A65E);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.secondaryBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      app.ministryAmharicTitle.isNotEmpty ? app.ministryAmharicTitle : app.ministryTitle,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                    ),
                    Text(
                      app.ministryTitle,
                      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor.withOpacity(0.5)),
                ),
                child: Text(
                  app.status == ApplicationStatus.pending
                      ? 'PENDING COORDINATOR'
                      : app.status.name.toUpperCase(),
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: statusColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.bookmark_border, size: 13, color: AppTheme.goldLight),
              const SizedBox(width: 4),
              Text('Sub-wing: ${app.preferredSubWing}', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
              const Spacer(),
              Text('Batch: ${app.studentYear}', style: const TextStyle(fontSize: 11, color: AppTheme.textTertiary)),
            ],
          ),
          if (app.coordinatorNotes != null && app.coordinatorNotes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.comment, size: 14, color: Color(0xFFF5A65E)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Coordinator note: ${app.coordinatorNotes}',
                      style: const TextStyle(fontSize: 11, color: AppTheme.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMinistryCard(MinistryModel min) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.secondaryBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderMuted),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Icon + Amharic/English Titles + Pillar Tag
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.goldAccent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.goldAccent.withOpacity(0.25)),
                ),
                child: Icon(_getMinistryIcon(min.iconName), color: AppTheme.goldLight, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      min.titleAmharic,
                      style: const TextStyle(
                        fontFamily: 'serif',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      min.titleEn,
                      style: const TextStyle(fontSize: 12, color: Color(0xFFF5A65E), fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceElevated,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        min.pillar.shortName.toUpperCase(),
                        style: const TextStyle(fontSize: 9, color: AppTheme.textTertiary, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Descriptions
          Text(
            min.descriptionAmharic,
            style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary, height: 1.35),
          ),
          const SizedBox(height: 4),
          Text(
            min.descriptionEn,
            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, height: 1.3),
          ),

          const SizedBox(height: 12),

          // Sub-wings Pills
          const Text('SUB-WINGS / ዘርፎች:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textTertiary, letterSpacing: 0.5)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: min.subWings.map((wing) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.borderMuted),
                ),
                child: Text(wing, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
              );
            }).toList(),
          ),

          const SizedBox(height: 12),

          // Meeting Schedule & Requirements
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF141C29),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.schedule, size: 14, color: AppTheme.goldLight),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Meeting: ${min.meetingSchedule}',
                        style: const TextStyle(fontSize: 11, color: Colors.white70),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.checklist, size: 14, color: Color(0xFFF5A65E)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        min.requirements,
                        style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          const Divider(color: AppTheme.borderMuted),
          const SizedBox(height: 8),

          // Coordinator Contact & Apply Action
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lead: ${min.teamLead} (${min.coordinatorBaptismalName})',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    Text(
                      '${min.activeCount} servants • ${min.openSlots} open slots',
                      style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              // Direct Inquiry Shortcuts
              IconButton(
                icon: const Icon(Icons.phone_outlined, size: 18, color: AppTheme.goldLight),
                tooltip: 'Call Coordinator',
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
                onPressed: () => widget.state.launchCall(min.coordinatorPhone),
              ),
              IconButton(
                icon: const Icon(Icons.sms_outlined, size: 18, color: AppTheme.goldLight),
                tooltip: 'SMS Coordinator',
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
                onPressed: () => widget.state.launchSms(
                  min.coordinatorPhone,
                  body: 'Selam Coordinator ${min.teamLead}, I am inquiring about joining ${min.titleAmharic}.',
                ),
              ),
              const SizedBox(width: 6),
              ElevatedButton(
                onPressed: () => _openApplicationDialog(context, min),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF5A65E),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
                child: const Text(
                  'Apply',
                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
