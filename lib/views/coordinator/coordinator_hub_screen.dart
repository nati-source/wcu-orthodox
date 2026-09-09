import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/app_models.dart';
import '../../state/fellowship_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/interactive_fellowship_card.dart';

/// Dedicated & Specialized Hub for Volunteer Coordinators of the 10 EOTC Fellowship Departments.
///
/// Scoped Permissions:
/// - Volunteer Coordinators cannot assign roles.
/// - Volunteer Coordinators cannot accept/reject general student registrations into fellowship.
/// - Volunteer Coordinators cannot schedule priests/confessors.
/// - Emergency Student Aid review is strictly restricted to 'አባላት እንክብካቤ፤ ምክክርና አቅም ማጎልበቻ' (deptMemberCare).
/// - Pilgrimage Trip Payment verification & trip management is strictly restricted to 'ባችና መርሐ ግብራት' (deptBatchPrograms).
/// - Charity & Vocational management & treasury is strictly restricted to 'ሙያና በጎ አድራጎት' (deptCharity).
/// - Each coordinator gets an interactive, customized department control room tailored to their ministry.
class CoordinatorHubScreen extends StatefulWidget {
  final FellowshipState state;

  const CoordinatorHubScreen({super.key, required this.state});

  @override
  State<CoordinatorHubScreen> createState() => _CoordinatorHubScreenState();
}

class _CoordinatorHubScreenState extends State<CoordinatorHubScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  ChoirWingType? _choirWingFilter; // For Music Department: Mezmur vs Fine Arts

  // Interactive Pilgrimage Controls (ባችና መርሐ ግብራት)
  String _pilgrimFilter = 'All'; // 'All', 'Pending Approval', 'Verified', 'Declined'
  String _pilgrimSearch = '';
  String? _selectedTripFilter; // null = all trips

  // Interactive Charity Controls (ሙያና በጎ አድራጎት)
  int _charityLedgerTab = 0; // 0: Campaigns, 1: Donations/Dues Inflow, 2: Aid Disbursements Outflow
  String _charitySearch = '';
  String _charityDuesStatusFilter = 'All'; // 'All', 'Pending', 'Verified'

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final coordProfile = state.currentUser.coordinatorProfile;
    final deptId = coordProfile?.departmentId ?? FellowshipDepartmentConstants.deptMemberCare;
    final isAudit = coordProfile?.isReadOnlyAudit == true;

    final deptAmharic = FellowshipDepartmentConstants.getNameAmharic(deptId);
    final deptEn = FellowshipDepartmentConstants.getNameEn(deptId);

    final apps = state.getApplicationsForDepartment(deptId);
    final pendingApps = apps.where((a) => a.status == ApplicationStatus.pending).toList();
    final members = state.getMembersForDepartment(deptId);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Coordinator Hub • ማስተባበሪያ',
              style: TextStyle(
                fontFamily: 'serif',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            Text(
              '$deptAmharic ($deptEn)',
              style: TextStyle(
                fontSize: 11,
                color: primaryAccent,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          // Quick Department Switcher for Demo / Simulation
          PopupMenuButton<String>(
            tooltip: 'Switch Active Department',
            icon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: primaryAccent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primaryAccent.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.hub_outlined, size: 14, color: primaryAccent),
                  const SizedBox(width: 4),
                  Text('Switch Dept', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: primaryAccent)),
                  Icon(Icons.arrow_drop_down, size: 14, color: primaryAccent),
                ],
              ),
            ),
            color: theme.cardTheme.color ?? theme.colorScheme.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            onSelected: (newDeptId) {
              HapticFeedback.mediumImpact();
              state.switchCoordinatorDepartment(newDeptId);
            },
            itemBuilder: (ctx) {
              return FellowshipDepartmentConstants.allDepartmentIds.map((id) {
                final isCurrent = id == deptId;
                final isAud = id == FellowshipDepartmentConstants.deptAudit;
                return PopupMenuItem<String>(
                  value: id,
                  child: Row(
                    children: [
                      Icon(
                        isAud ? Icons.fact_check_outlined : Icons.account_tree_outlined,
                        size: 16,
                        color: isCurrent ? primaryAccent : (theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${FellowshipDepartmentConstants.getNameAmharic(id)} ${isAud ? "(Audit)" : ""}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                            color: isCurrent ? primaryAccent : theme.colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList();
            },
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: primaryAccent,
          labelColor: primaryAccent,
          unselectedLabelColor: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: [
            Tab(text: 'Department Tasks (${_getDeptSpecificBadgeCount(state, deptId)})'),
            Tab(text: 'Applications (${pendingApps.length})'),
            Tab(text: 'Volunteers Roster (${members.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Department-Specialized Interactive Workflows
          _buildDepartmentSpecializedView(context, state, deptId, isAudit),

          // Tab 2: Scoped Volunteer Applications for THIS Department
          _buildDepartmentApplicationsTab(context, state, deptId, pendingApps, isAudit),

          // Tab 3: Active Volunteers Roster
          _buildDepartmentRosterTab(context, state, deptId, members, isAudit),
        ],
      ),
    );
  }

  int _getDeptSpecificBadgeCount(FellowshipState state, String deptId) {
    if (deptId == FellowshipDepartmentConstants.deptMemberCare) {
      return state.emergencyAidRequests.where((r) => r.status == EmergencyAidStatus.underReview).length;
    } else if (deptId == FellowshipDepartmentConstants.deptBatchPrograms) {
      return state.allTripRegistrations.where((r) => r.paymentStatus == TripPaymentStatus.pendingVerification).length;
    } else if (deptId == FellowshipDepartmentConstants.deptCharity) {
      return state.duesPayments.where((d) => d.status == 'Pending Verification').length;
    }
    return state.getApplicationsForDepartment(deptId).length;
  }

  // ============================================================================
  // TAB 1: DEPARTMENT SPECIALIZED INTERACTIVE WORKFLOWS
  // ============================================================================
  Widget _buildDepartmentSpecializedView(BuildContext context, FellowshipState state, String deptId, bool isAudit) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 1. Department Identity Card
        _buildDepartmentBannerCard(context, state, deptId, isAudit),
        const SizedBox(height: 16),

        // 2. Department Quick Metrics Matrix
        _buildDepartmentKpis(context, state, deptId),
        const SizedBox(height: 20),

        // 3. Department Specific Dedicated Interactive Modules
        if (deptId == FellowshipDepartmentConstants.deptMemberCare)
          _buildMemberCareModule(context, state, isAudit)
        else if (deptId == FellowshipDepartmentConstants.deptChoirArts)
          _buildChoirAndArtsModule(context, state, isAudit)
        else if (deptId == FellowshipDepartmentConstants.deptBatchPrograms)
          _buildBatchProgramsModule(context, state, isAudit)
        else if (deptId == FellowshipDepartmentConstants.deptEducation)
          _buildEducationModule(context, state, isAudit)
        else if (deptId == FellowshipDepartmentConstants.deptDevelopment)
          _buildDevelopmentModule(context, state, isAudit)
        else if (deptId == FellowshipDepartmentConstants.deptFinanceProperty)
          _buildFinancePropertyModule(context, state, isAudit)
        else if (deptId == FellowshipDepartmentConstants.deptCharity)
          _buildCharityModule(context, state, isAudit)
        else if (deptId == FellowshipDepartmentConstants.deptSpecialNeeds)
          _buildSpecialNeedsModule(context, state, isAudit)
        else if (deptId == FellowshipDepartmentConstants.deptPlanning)
          _buildPlanningModule(context, state, isAudit)
        else if (deptId == FellowshipDepartmentConstants.deptAudit)
          _buildAuditModule(context, state)
        else
          _buildGenericDepartmentModule(context, state, deptId),

        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildDepartmentBannerCard(BuildContext context, FellowshipState state, String deptId, bool isAudit) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final deptAmharic = FellowshipDepartmentConstants.getNameAmharic(deptId);
    final deptEn = FellowshipDepartmentConstants.getNameEn(deptId);

    return InteractiveFellowshipCard(
      padding: const EdgeInsets.all(18),
      color: theme.cardTheme.color ?? theme.colorScheme.surface,
      borderColor: isAudit ? const Color(0xFFF5A65E).withOpacity(0.5) : primaryAccent.withOpacity(0.4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (isAudit ? const Color(0xFFF5A65E) : primaryAccent).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  isAudit ? Icons.fact_check_outlined : Icons.shield_outlined,
                  color: isAudit ? const Color(0xFFF5A65E) : primaryAccent,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      deptAmharic,
                      style: TextStyle(
                        fontFamily: 'serif',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      deptEn,
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  isAudit ? Icons.lock_outline : Icons.verified_user_outlined,
                  size: 14,
                  color: isAudit ? const Color(0xFFF5A65E) : AppTheme.emerald,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    isAudit
                        ? 'Inspection Role: Read-only observation & audit logs across all units.'
                        : 'Coordinator Scope: Delegated department management & volunteer review.',
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDepartmentKpis(BuildContext context, FellowshipState state, String deptId) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final apps = state.getApplicationsForDepartment(deptId);
    final pendingCount = apps.where((a) => a.status == ApplicationStatus.pending).length;
    final memberCount = state.getMembersForDepartment(deptId).length;

    return Row(
      children: [
        Expanded(
          child: _buildMetricTile(
            context,
            title: 'Active Servants',
            value: '$memberCount',
            icon: Icons.groups_outlined,
            color: primaryAccent,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMetricTile(
            context,
            title: 'Pending Apps',
            value: '$pendingCount',
            icon: Icons.assignment_ind_outlined,
            color: const Color(0xFFF59E0B),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMetricTile(
            context,
            title: 'Duty Shifts',
            value: 'Active',
            icon: Icons.calendar_today_outlined,
            color: const Color(0xFF10B981),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricTile(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(fontSize: 10, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // DEPARTMENT 2: አባላት እንክብካቤ፤ ምክክርና አቅም ማጎልበቻ (MEMBER CARE & COUNSELING)
  // --------------------------------------------------------------------------
  Widget _buildMemberCareModule(BuildContext context, FellowshipState state, bool isAudit) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final aidRequests = state.emergencyAidRequests;
    final pendingAid = aidRequests.where((r) => r.status == EmergencyAidStatus.underReview).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'የተማሪዎች አስቸኳይ ድጋፍና ምክክር (EMERGENCY AID REVIEW)',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: primaryAccent, letterSpacing: 1.1),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: primaryAccent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('${pendingAid.length} Pending Review', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: primaryAccent)),
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (pendingAid.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardTheme.color ?? theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: AppTheme.emerald, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'All member emergency aid and welfare applications are processed.',
                    style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary),
                  ),
                ),
              ],
            ),
          )
        else
          ...pendingAid.map((req) {
            return InteractiveFellowshipCard(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              color: theme.cardTheme.color ?? theme.colorScheme.surface,
              borderColor: primaryAccent.withOpacity(0.3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          req.studentName,
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('${req.amountRequested.toStringAsFixed(0)} ETB', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFF59E0B))),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('B.N. ${req.studentBaptismalName} • Phone: ${req.studentPhone}', style: TextStyle(fontSize: 11, color: primaryAccent, fontWeight: FontWeight.w600)),
                  Text('Category: ${req.category.displayName}', style: TextStyle(fontSize: 11, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary)),
                  const SizedBox(height: 6),
                  Text(
                    req.description,
                    style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface, fontStyle: FontStyle.italic),
                  ),
                  if (!isAudit) ...[
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            state.verifyEmergencyAid(req.id, EmergencyAidStatus.declined, adminNote: 'Declined by Member Care Coordinator');
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Emergency aid request for ${req.studentName} marked as declined.')),
                            );
                          },
                          style: OutlinedButton.styleFrom(foregroundColor: AppTheme.crimson),
                          child: const Text('Decline', style: TextStyle(fontSize: 11)),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            state.verifyEmergencyAid(req.id, EmergencyAidStatus.approved, adminNote: 'Approved by Member Care Coordinator');
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Emergency aid for ${req.studentName} approved for disbursement.')),
                            );
                          },
                          icon: const Icon(Icons.check, size: 14, color: Colors.white),
                          label: const Text('Approve & Disburse', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            );
          }),

        const SizedBox(height: 16),

        // Capacity & Spiritual Welfare Tracker
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardTheme.color ?? theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Student Welfare & Counseling Follow-up',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
              ),
              const SizedBox(height: 4),
              Text(
                'Monitor freshman adaptation, coordinate prayer families, and support students needing psychological or spiritual counseling.',
                style: TextStyle(fontSize: 11, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary, height: 1.3),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildActionChip(context, Icons.psychology_outlined, 'Counseling Cases'),
                  _buildActionChip(context, Icons.favorite_outline, 'Freshman Visits'),
                  _buildActionChip(context, Icons.event_available_outlined, 'Capacity Workshops'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // DEPARTMENT 3: መዝሙርና ስነ ጥበባት (MUSIC, HYMNOGRAPHY & SACRED ARTS)
  // --------------------------------------------------------------------------
  Widget _buildChoirAndArtsModule(BuildContext context, FellowshipState state, bool isAudit) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'የዝማሬና ስነ-ጥበባት አስተዳደር (CHOIR & SACRED ARTS CONTROL)',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: primaryAccent, letterSpacing: 1.1),
        ),
        const SizedBox(height: 10),

        // Dual Wing Filter Selector with SingleChildScrollView to prevent overflow
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ChoiceChip(
                label: const Text('All Wings (ሁለቱም)'),
                selected: _choirWingFilter == null,
                onSelected: (val) => setState(() => _choirWingFilter = null),
                selectedColor: primaryAccent.withOpacity(0.2),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('St. Yared Mezmur'),
                selected: _choirWingFilter == ChoirWingType.mezmur,
                onSelected: (val) => setState(() => _choirWingFilter = ChoirWingType.mezmur),
                selectedColor: primaryAccent.withOpacity(0.2),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Fine Arts & Drama'),
                selected: _choirWingFilter == ChoirWingType.fineArts,
                onSelected: (val) => setState(() => _choirWingFilter = ChoirWingType.fineArts),
                selectedColor: primaryAccent.withOpacity(0.2),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Practice & Liturgy Rehearsal Schedule Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardTheme.color ?? theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Weekly Liturgy Rehearsal Schedule', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                  Icon(Icons.music_note, color: primaryAccent, size: 20),
                ],
              ),
              const SizedBox(height: 8),
              _buildScheduleRow(context, 'Friday 11:30 LT', 'Saint Yared Digua & Mahlet Practice (Ge\'ez)'),
              const SizedBox(height: 6),
              _buildScheduleRow(context, 'Saturday 10:00 LT', 'Sunday Liturgy Choir Hymns & Drum (Kebero) Roster'),
              const SizedBox(height: 6),
              _buildScheduleRow(context, 'Sunday 2:00 LT', 'Sunday School Drama & Orthodox Poetry Rehearsal'),
            ],
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // DEPARTMENT 6: ባችና መርሐ ግብራት (BATCH & PROGRAMS COORDINATION)
  // Dedicated to: Interactive Pilgrimage Management (Add/Edit/Delete Trips & Pilgrims, Money Control & Approvals)
  // --------------------------------------------------------------------------
  Widget _buildBatchProgramsModule(BuildContext context, FellowshipState state, bool isAudit) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final trips = state.pilgrimageTrips;
    final allRegistrations = state.allTripRegistrations;

    // Filter registrations based on selected trip, status filter, and search query
    final filteredRegistrations = allRegistrations.where((r) {
      if (_selectedTripFilter != null && r.tripId != _selectedTripFilter) {
        return false;
      }
      if (_pilgrimFilter == 'Pending Approval' && r.paymentStatus != TripPaymentStatus.pendingVerification) {
        return false;
      }
      if (_pilgrimFilter == 'Verified' && r.paymentStatus != TripPaymentStatus.verified && r.paymentStatus != TripPaymentStatus.free) {
        return false;
      }
      if (_pilgrimFilter == 'Declined' && r.paymentStatus != TripPaymentStatus.rejected) {
        return false;
      }
      if (_pilgrimSearch.isNotEmpty) {
        final q = _pilgrimSearch.toLowerCase();
        final matchName = r.studentName.toLowerCase().contains(q);
        final matchBap = r.studentBaptismalName.toLowerCase().contains(q);
        final matchPhone = r.studentPhone.toLowerCase().contains(q);
        final matchRef = r.transactionReference.toLowerCase().contains(q);
        final matchTrip = r.tripTitle.toLowerCase().contains(q);
        if (!matchName && !matchBap && !matchPhone && !matchRef && !matchTrip) {
          return false;
        }
      }
      return true;
    }).toList();

    final pendingCount = allRegistrations.where((r) => r.paymentStatus == TripPaymentStatus.pendingVerification).length;
    final verifiedCount = allRegistrations.where((r) => r.paymentStatus == TripPaymentStatus.verified || r.paymentStatus == TripPaymentStatus.free).length;
    final rejectedCount = allRegistrations.where((r) => r.paymentStatus == TripPaymentStatus.rejected).length;

    // Financial Calculation for Pilgrimages
    final totalExpectedRevenue = trips.fold<double>(0.0, (sum, t) => sum + (t.totalSeats * t.feeAmount));
    final totalVerifiedRevenue = allRegistrations.where((r) => r.paymentStatus == TripPaymentStatus.verified).fold<double>(0.0, (sum, r) => sum + r.feeAmount);
    final totalPendingRevenue = allRegistrations.where((r) => r.paymentStatus == TripPaymentStatus.pendingVerification).fold<double>(0.0, (sum, r) => sum + r.feeAmount);
    final collectionProgress = totalExpectedRevenue > 0 ? (totalVerifiedRevenue / totalExpectedRevenue).clamp(0.0, 1.0) : 0.0;

    // Payment channel breakdown
    final telebirrAmount = allRegistrations.where((r) => r.paymentMethod == PaymentMethodType.telebirr && r.paymentStatus == TripPaymentStatus.verified).fold<double>(0.0, (s, r) => s + r.feeAmount);
    final cbeAmount = allRegistrations.where((r) => r.paymentMethod == PaymentMethodType.cbeBirr && r.paymentStatus == TripPaymentStatus.verified).fold<double>(0.0, (s, r) => s + r.feeAmount);
    final cashAmount = allRegistrations.where((r) => r.paymentMethod == PaymentMethodType.cash && r.paymentStatus == TripPaymentStatus.verified).fold<double>(0.0, (s, r) => s + r.feeAmount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Pilgrimage Financial / Money Controlling Dashboard Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                primaryAccent.withOpacity(0.16),
                theme.cardTheme.color ?? theme.colorScheme.surface,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: primaryAccent.withOpacity(0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.account_balance_wallet_outlined, color: primaryAccent, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Pilgrimage Treasury & Money Control • የጉዞ በጀትና ካዝና',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('Live Treasury', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _buildFinancialSubTile(
                      context,
                      label: 'Verified Collected',
                      amount: '${totalVerifiedRevenue.toStringAsFixed(0)} ETB',
                      color: const Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildFinancialSubTile(
                      context,
                      label: 'Pending Verification',
                      amount: '${totalPendingRevenue.toStringAsFixed(0)} ETB',
                      color: const Color(0xFFF59E0B),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildFinancialSubTile(
                      context,
                      label: 'Target Budget',
                      amount: '${totalExpectedRevenue.toStringAsFixed(0)} ETB',
                      color: primaryAccent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Collection Progress Indicator
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: collectionProgress,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(primaryAccent),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Progress: ${(collectionProgress * 100).toStringAsFixed(1)}% Collected', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: primaryAccent)),
                  Text('${allRegistrations.length} Total Registered', style: TextStyle(fontSize: 10, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary)),
                ],
              ),
              const SizedBox(height: 10),
              // Payment Channels Breakdown
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildMiniBadge(context, 'Telebirr: ${telebirrAmount.toStringAsFixed(0)} ETB', const Color(0xFF3B82F6)),
                    const SizedBox(width: 6),
                    _buildMiniBadge(context, 'CBE Birr: ${cbeAmount.toStringAsFixed(0)} ETB', const Color(0xFF8B5CF6)),
                    const SizedBox(width: 6),
                    _buildMiniBadge(context, 'Cash: ${cashAmount.toStringAsFixed(0)} ETB', const Color(0xFF10B981)),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // 2. Action Toolbar: Add New Trip & Add Pilgrim Student
        if (!isAudit) ...[
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _openAddPilgrimageTripModal(context, state),
                  icon: const Icon(Icons.add_location_alt, size: 16, color: Colors.white),
                  label: const Text('Add Pilgrimage Trip', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryAccent,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _openAddPilgrimStudentModal(context, state),
                  icon: Icon(Icons.person_add_alt_1, size: 16, color: primaryAccent),
                  label: Text('Register Pilgrim', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryAccent)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: primaryAccent),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
        ],

        // 3. Active Pilgrimage Trips List (with Edit & Delete)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'ACTIVE PILGRIMAGE TRIPS (${trips.length})',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: primaryAccent, letterSpacing: 1.1),
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (trips.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardTheme.color ?? theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Text('No active trips created. Tap "Add Pilgrimage Trip" above.', style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary)),
          )
        else
          ...trips.map((trip) {
            final tripRegs = allRegistrations.where((r) => r.tripId == trip.id).toList();
            final tripVerified = tripRegs.where((r) => r.paymentStatus == TripPaymentStatus.verified).fold<double>(0.0, (s, r) => s + r.feeAmount);
            final isFilterActive = _selectedTripFilter == trip.id;

            return InteractiveFellowshipCard(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              color: theme.cardTheme.color ?? theme.colorScheme.surface,
              borderColor: isFilterActive ? primaryAccent : primaryAccent.withOpacity(0.3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          trip.title,
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: primaryAccent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          trip.isFree ? 'Free Trip' : '${trip.feeAmount.toStringAsFixed(0)} ETB',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryAccent),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Monastery: ${trip.destination} • Date: ${trip.departureDate.year}-${trip.departureDate.month}-${trip.departureDate.day}',
                    style: TextStyle(fontSize: 11, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Booked: ${trip.bookedSeats} / ${trip.totalSeats} Seats • ${tripRegs.length} Registered',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: primaryAccent),
                      ),
                      Text(
                        'Collected: ${tripVerified.toStringAsFixed(0)} ETB',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Filter shortcut button
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            if (_selectedTripFilter == trip.id) {
                              _selectedTripFilter = null;
                            } else {
                              _selectedTripFilter = trip.id;
                            }
                          });
                        },
                        icon: Icon(isFilterActive ? Icons.filter_alt_off : Icons.filter_alt, size: 14),
                        label: Text(isFilterActive ? 'Show All Trips' : 'View Passengers (${tripRegs.length})', style: const TextStyle(fontSize: 11)),
                      ),
                      if (!isAudit)
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: AppTheme.crimson, size: 18),
                              tooltip: 'Delete Trip',
                              onPressed: () {
                                _confirmDeleteDialog(
                                  context,
                                  title: 'Delete Pilgrimage Trip',
                                  message: 'Are you sure you want to delete "${trip.title}" and cancel all its registered tickets?',
                                  onConfirm: () {
                                    state.removePilgrimageTrip(trip.id);
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Trip "${trip.title}" removed.')));
                                  },
                                );
                              },
                            ),
                            OutlinedButton.icon(
                              onPressed: () => _openEditTripModal(context, state, trip),
                              icon: const Icon(Icons.edit, size: 12),
                              label: const Text('Edit Trip', style: TextStyle(fontSize: 11)),
                              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6)),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            );
          }),

        const SizedBox(height: 18),

        // 4. Interactive Approvals & Passenger Roster with Filters & Search
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'PILGRIMS APPROVALS & PASSENGER ROSTER',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: primaryAccent, letterSpacing: 1.1),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Search Bar for Pilgrims
        TextField(
          decoration: InputDecoration(
            hintText: 'Search by passenger, baptismal name, phone or ref...',
            hintStyle: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary),
            prefixIcon: const Icon(Icons.search, size: 18),
            suffixIcon: _pilgrimSearch.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 16),
                    onPressed: () => setState(() => _pilgrimSearch = ''),
                  )
                : null,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            filled: true,
            fillColor: theme.cardTheme.color ?? theme.colorScheme.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: theme.dividerColor)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: theme.dividerColor)),
          ),
          onChanged: (val) => setState(() => _pilgrimSearch = val.trim()),
        ),
        const SizedBox(height: 10),

        // Filter Tabs
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ChoiceChip(
                label: Text('All (${allRegistrations.length})'),
                selected: _pilgrimFilter == 'All',
                onSelected: (val) => setState(() => _pilgrimFilter = 'All'),
                selectedColor: primaryAccent.withOpacity(0.2),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: Text('Pending Approval ($pendingCount)'),
                selected: _pilgrimFilter == 'Pending Approval',
                onSelected: (val) => setState(() => _pilgrimFilter = 'Pending Approval'),
                selectedColor: const Color(0xFFF59E0B).withOpacity(0.2),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: Text('Verified ($verifiedCount)'),
                selected: _pilgrimFilter == 'Verified',
                onSelected: (val) => setState(() => _pilgrimFilter = 'Verified'),
                selectedColor: const Color(0xFF10B981).withOpacity(0.2),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: Text('Declined ($rejectedCount)'),
                selected: _pilgrimFilter == 'Declined',
                onSelected: (val) => setState(() => _pilgrimFilter = 'Declined'),
                selectedColor: AppTheme.crimson.withOpacity(0.2),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        if (filteredRegistrations.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardTheme.color ?? theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Center(
              child: Text(
                'No pilgrim registrations found for the selected filter.',
                style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary),
              ),
            ),
          )
        else
          ...filteredRegistrations.map((reg) {
            final isPending = reg.paymentStatus == TripPaymentStatus.pendingVerification;
            final isVerified = reg.paymentStatus == TripPaymentStatus.verified || reg.paymentStatus == TripPaymentStatus.free;
            final isRejected = reg.paymentStatus == TripPaymentStatus.rejected;

            return InteractiveFellowshipCard(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              color: theme.cardTheme.color ?? theme.colorScheme.surface,
              borderColor: isPending ? const Color(0xFFF59E0B).withOpacity(0.5) : theme.dividerColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: (isVerified
                                ? const Color(0xFF10B981)
                                : isPending
                                    ? const Color(0xFFF59E0B)
                                    : AppTheme.crimson)
                            .withOpacity(0.15),
                        child: Text(
                          reg.studentName.isNotEmpty ? reg.studentName[0] : 'P',
                          style: TextStyle(
                            color: isVerified
                                ? const Color(0xFF10B981)
                                : isPending
                                    ? const Color(0xFFF59E0B)
                                    : AppTheme.crimson,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              reg.studentName,
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'B.N. ${reg.studentBaptismalName} • Bus #${reg.busNumber} Seat #${reg.seatNumber}',
                              style: TextStyle(fontSize: 11, color: primaryAccent, fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Trip: ${reg.tripTitle}',
                              style: TextStyle(fontSize: 10, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: (isVerified
                                      ? const Color(0xFF10B981)
                                      : isPending
                                          ? const Color(0xFFF59E0B)
                                          : AppTheme.crimson)
                                  .withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isVerified
                                  ? 'Verified'
                                  : isPending
                                      ? 'Pending'
                                      : 'Declined',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isVerified
                                    ? const Color(0xFF10B981)
                                    : isPending
                                        ? const Color(0xFFF59E0B)
                                        : AppTheme.crimson,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${reg.feeAmount.toStringAsFixed(0)} ETB',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.tag, size: 12, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Ref: ${reg.transactionReference} (${reg.paymentMethod.displayName})',
                            style: TextStyle(fontSize: 10, fontFamily: 'monospace', color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: reg.transactionReference));
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transaction Ref copied!')));
                          },
                          child: Icon(Icons.copy, size: 12, color: primaryAccent),
                        ),
                      ],
                    ),
                  ),

                  // Actions row (Verify, Reject, View Ticket, Edit, Delete)
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    alignment: WrapAlignment.end,
                    children: [
                      // View E-Ticket button
                      OutlinedButton.icon(
                        onPressed: () => _openPilgrimTicketModal(context, state, reg),
                        icon: const Icon(Icons.qr_code, size: 12),
                        label: const Text('E-Ticket', style: TextStyle(fontSize: 11)),
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
                      ),
                      if (!isAudit) ...[
                        // Edit Passenger Details
                        OutlinedButton.icon(
                          onPressed: () => _openEditPilgrimStudentModal(context, state, reg),
                          icon: const Icon(Icons.edit, size: 12),
                          label: const Text('Edit / Seat', style: TextStyle(fontSize: 11)),
                          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
                        ),
                        // Delete / Cancel Ticket
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: AppTheme.crimson, size: 18),
                          tooltip: 'Cancel Pilgrim Ticket',
                          onPressed: () {
                            _confirmDeleteDialog(
                              context,
                              title: 'Cancel Pilgrim Ticket',
                              message: 'Are you sure you want to cancel ticket for ${reg.studentName}?',
                              onConfirm: () {
                                state.deletePilgrimRegistration(reg.id);
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Pilgrim ${reg.studentName} removed.')));
                              },
                            );
                          },
                        ),
                        if (isPending) ...[
                          OutlinedButton(
                            onPressed: () {
                              HapticFeedback.selectionClick();
                              state.verifyTripPayment(reg.id, false);
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Payment for ${reg.studentName} marked as invalid.')));
                            },
                            style: OutlinedButton.styleFrom(foregroundColor: AppTheme.crimson, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
                            child: const Text('Reject', style: TextStyle(fontSize: 11)),
                          ),
                          ElevatedButton.icon(
                            onPressed: () {
                              HapticFeedback.mediumImpact();
                              state.verifyTripPayment(reg.id, true);
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Payment verified & Boarding pass issued to ${reg.studentName}')));
                            },
                            icon: const Icon(Icons.check, size: 12, color: Colors.white),
                            label: const Text('Verify & Issue', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4)),
                          ),
                        ],
                      ],
                    ],
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // DEPARTMENT 7: ሙያና በጎ አድራጎት (CHARITY & VOCATIONAL ACTIVITIES)
  // Dedicated to: Interactive Charity Campaigns, Donations Inflow, Aid Disbursements Outflow & Treasury Control
  // --------------------------------------------------------------------------
  Widget _buildCharityModule(BuildContext context, FellowshipState state, bool isAudit) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final campaigns = state.charityCampaigns;
    final duesPayments = state.duesPayments;
    final disbursements = state.charityDisbursements;

    // Financial Calculation for Charity
    final totalCampaignsRaised = campaigns.fold<double>(0.0, (sum, c) => sum + c.raisedAmount);
    final totalTargetBudget = campaigns.fold<double>(0.0, (sum, c) => sum + c.targetAmount);
    final totalDuesCollected = duesPayments.where((d) => d.status == 'Verified').fold<double>(0.0, (sum, d) => sum + d.amount);
    final totalAidDisbursed = disbursements.fold<double>(0.0, (sum, d) => sum + d.amount);
    final totalGrossInflow = totalCampaignsRaised + totalDuesCollected;
    final netTreasuryBalance = totalGrossInflow - totalAidDisbursed;
    final totalDonors = campaigns.fold<int>(0, (sum, c) => sum + c.donorsCount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Charity Treasury / Money Controlling Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF10B981).withOpacity(0.16),
                theme.cardTheme.color ?? theme.colorScheme.surface,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF10B981).withOpacity(0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.volunteer_activism_outlined, color: Color(0xFF10B981), size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Charity Treasury & Vault Control • የበጎ አድራጎት ካዝና',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('$totalDonors Donors', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _buildFinancialSubTile(
                      context,
                      label: 'Gross Inflow',
                      amount: '${totalGrossInflow.toStringAsFixed(0)} ETB',
                      color: const Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildFinancialSubTile(
                      context,
                      label: 'Aid Disbursed',
                      amount: '${totalAidDisbursed.toStringAsFixed(0)} ETB',
                      color: AppTheme.crimson,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildFinancialSubTile(
                      context,
                      label: 'Net Balance',
                      amount: '${netTreasuryBalance.toStringAsFixed(0)} ETB',
                      color: const Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Campaigns Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: totalTargetBudget > 0 ? (totalCampaignsRaised / totalTargetBudget).clamp(0.0, 1.0) : 0.0,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Campaigns Raised: ${totalCampaignsRaised.toStringAsFixed(0)} ETB', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                  Text('Goal: ${totalTargetBudget.toStringAsFixed(0)} ETB', style: TextStyle(fontSize: 10, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary)),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // 2. Action Toolbar: Add Campaign & Record Donation & Disburse Aid
        if (!isAudit) ...[
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _openAddCharityCampaignModal(context, state),
                  icon: const Icon(Icons.add_task, size: 14, color: Colors.white),
                  label: const Text('Add Campaign', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _openRecordDonationModal(context, state),
                  icon: const Icon(Icons.payments_outlined, size: 14, color: Color(0xFF10B981)),
                  label: const Text('Record Donation', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: Color(0xFF10B981)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _openDisburseAidModal(context, state),
                  icon: const Icon(Icons.handshake_outlined, size: 14, color: AppTheme.crimson),
                  label: const Text('Disburse Aid', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.crimson)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: AppTheme.crimson),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
        ],

        // 3. Sub-Section Navigation Tabs (Campaigns, Donations Inflow, Aid Disbursements Outflow)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ChoiceChip(
                label: Text('Campaigns (${campaigns.length})'),
                selected: _charityLedgerTab == 0,
                onSelected: (val) => setState(() => _charityLedgerTab = 0),
                selectedColor: const Color(0xFF10B981).withOpacity(0.2),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: Text('Donations & Dues (${duesPayments.length})'),
                selected: _charityLedgerTab == 1,
                onSelected: (val) => setState(() => _charityLedgerTab = 1),
                selectedColor: const Color(0xFF10B981).withOpacity(0.2),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: Text('Aid Disbursements (${disbursements.length})'),
                selected: _charityLedgerTab == 2,
                onSelected: (val) => setState(() => _charityLedgerTab = 2),
                selectedColor: AppTheme.crimson.withOpacity(0.2),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // SUB-TAB 0: CAMPAIGNS LIST
        if (_charityLedgerTab == 0) ...[
          if (campaigns.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardTheme.color ?? theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Text('No active charity campaigns. Tap "Add Campaign" above.', style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary)),
            )
          else
            ...campaigns.map((camp) {
              return InteractiveFellowshipCard(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                color: theme.cardTheme.color ?? theme.colorScheme.surface,
                borderColor: const Color(0xFF10B981).withOpacity(0.3),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            camp.title,
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${(camp.progressPercentage * 100).toStringAsFixed(0)}% Funded',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('Category: ${camp.category}', style: TextStyle(fontSize: 11, color: primaryAccent, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(camp.description, style: TextStyle(fontSize: 11, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary)),
                    const SizedBox(height: 8),

                    // Progress Bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: camp.progressPercentage,
                        backgroundColor: theme.colorScheme.surfaceContainerHighest,
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Raised: ${camp.raisedAmount.toStringAsFixed(0)} ETB (${camp.donorsCount} Donors)', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                        Text('Goal: ${camp.targetAmount.toStringAsFixed(0)} ETB', style: TextStyle(fontSize: 10, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary)),
                      ],
                    ),

                    if (!isAudit) ...[
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: AppTheme.crimson, size: 18),
                            tooltip: 'Delete Campaign',
                            onPressed: () {
                              _confirmDeleteDialog(
                                context,
                                title: 'Delete Charity Campaign',
                                message: 'Are you sure you want to delete "${camp.title}"?',
                                onConfirm: () {
                                  state.removeCharityCampaign(camp.id);
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Campaign "${camp.title}" deleted.')));
                                },
                              );
                            },
                          ),
                          const SizedBox(width: 4),
                          OutlinedButton.icon(
                            onPressed: () => _openEditCharityCampaignModal(context, state, camp),
                            icon: const Icon(Icons.edit, size: 12),
                            label: const Text('Edit Goal', style: TextStyle(fontSize: 11)),
                            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6)),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              );
            }),
        ],

        // SUB-TAB 1: DONATIONS & DUES INFLOW LEDGER
        if (_charityLedgerTab == 1) ...[
          if (duesPayments.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardTheme.color ?? theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Text('No donations or dues recorded yet.', style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary)),
            )
          else
            ...duesPayments.map((due) {
              final isVerified = due.status == 'Verified';
              return InteractiveFellowshipCard(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                color: theme.cardTheme.color ?? theme.colorScheme.surface,
                borderColor: isVerified ? theme.dividerColor : const Color(0xFFF59E0B).withOpacity(0.5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: const Color(0xFF10B981).withOpacity(0.15),
                          child: const Icon(Icons.receipt_long, color: Color(0xFF10B981), size: 18),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                due.studentName,
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${due.amount.toStringAsFixed(0)} ETB • ${due.purpose}',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'Ref: ${due.transactionReference} (${due.paymentMethod.displayName})',
                                style: TextStyle(fontSize: 10, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: (isVerified ? const Color(0xFF10B981) : const Color(0xFFF59E0B)).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            due.status,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isVerified ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (!isAudit) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (!isVerified) ...[
                            OutlinedButton(
                              onPressed: () {
                                HapticFeedback.selectionClick();
                                state.verifyDuesPayment(due.id, false);
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contribution declined.')));
                              },
                              style: OutlinedButton.styleFrom(foregroundColor: AppTheme.crimson, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
                              child: const Text('Decline', style: TextStyle(fontSize: 11)),
                            ),
                            const SizedBox(width: 6),
                            ElevatedButton(
                              onPressed: () {
                                HapticFeedback.mediumImpact();
                                state.verifyDuesPayment(due.id, true);
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contribution verified & added to Charity vault!')));
                              },
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
                              child: const Text('Verify', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                            ),
                            const SizedBox(width: 6),
                          ],
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: AppTheme.crimson, size: 18),
                            tooltip: 'Void / Delete Contribution',
                            onPressed: () {
                              _confirmDeleteDialog(
                                context,
                                title: 'Void Contribution',
                                message: 'Delete contribution record of ${due.amount.toStringAsFixed(0)} ETB from ${due.studentName}?',
                                onConfirm: () {
                                  state.deleteDuesPayment(due.id);
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contribution record deleted.')));
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              );
            }),
        ],

        // SUB-TAB 2: AID DISBURSEMENTS OUTFLOW LEDGER
        if (_charityLedgerTab == 2) ...[
          if (disbursements.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardTheme.color ?? theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Text('No aid disbursements recorded yet. Tap "Disburse Aid" above.', style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary)),
            )
          else
            ...disbursements.map((disb) {
              return InteractiveFellowshipCard(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                color: theme.cardTheme.color ?? theme.colorScheme.surface,
                borderColor: AppTheme.crimson.withOpacity(0.3),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: AppTheme.crimson.withOpacity(0.12),
                          child: const Icon(Icons.outbox, color: AppTheme.crimson, size: 18),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                disb.beneficiaryName,
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${disb.amount.toStringAsFixed(0)} ETB • ${disb.assistanceType}',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.crimson),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'Voucher: ${disb.voucherReference} • By: ${disb.approvedBy}',
                                style: TextStyle(fontSize: 10, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        if (!isAudit)
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: AppTheme.crimson, size: 18),
                            tooltip: 'Void Disbursement Record',
                            onPressed: () {
                              _confirmDeleteDialog(
                                context,
                                title: 'Void Disbursement',
                                message: 'Are you sure you want to void disbursement of ${disb.amount.toStringAsFixed(0)} ETB for ${disb.beneficiaryName}?',
                                onConfirm: () {
                                  state.deleteCharityDisbursement(disb.id);
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Disbursement record voided.')));
                                },
                              );
                            },
                          ),
                      ],
                    ),
                    if (disb.notes.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text('Note: ${disb.notes}', style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary)),
                    ],
                  ],
                ),
              );
            }),
        ],
      ],
    );
  }

  // --------------------------------------------------------------------------
  // DEPARTMENT 1: ትምህርትና ሐዋርያዊ አገልግሎት (EDUCATION & APOSTOLIC MINISTRY)
  // --------------------------------------------------------------------------
  Widget _buildEducationModule(BuildContext context, FellowshipState state, bool isAudit) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Apostolic Curriculum & Guest Teachers', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
              Icon(Icons.school, color: primaryAccent, size: 20),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Schedule Sunday catechism topics, dispatch special guest clergy lecture broadcasts, and coordinate study circles.',
            style: TextStyle(fontSize: 11, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildActionChip(context, Icons.campaign_outlined, 'Dispatch Guest Teacher Notice'),
              _buildActionChip(context, Icons.book_outlined, 'Review Syllabus Modules'),
              _buildActionChip(context, Icons.groups_outlined, 'Study Circle Rosters'),
            ],
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // DEPARTMENT 4: ልማትና ገቢ አሰባሰብ (DEVELOPMENT & FUNDRAISING)
  // --------------------------------------------------------------------------
  Widget _buildDevelopmentModule(BuildContext context, FellowshipState state, bool isAudit) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Fundraising & Development Proposals', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
              Icon(Icons.savings_outlined, color: primaryAccent, size: 20),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Submit capital project budgets, track annual fellowship dues campaigns, and manage donor pledge registries.',
            style: TextStyle(fontSize: 11, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildActionChip(context, Icons.post_add, 'Draft Project Proposal'),
              _buildActionChip(context, Icons.volunteer_activism, 'Dues Campaign Tracker'),
            ],
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // DEPARTMENT 5: ሒሳብና ንብረት (ACCOUNTING & PROPERTY)
  // --------------------------------------------------------------------------
  Widget _buildFinancePropertyModule(BuildContext context, FellowshipState state, bool isAudit) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Church Property & Assets Registry', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
              Icon(Icons.account_balance_outlined, color: primaryAccent, size: 20),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Track sacred vestments, sound system equipment, and liturgical books inventory.',
            style: TextStyle(fontSize: 11, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // DEPARTMENT 8: ቋንቋና ልዩ ልዩ ፍላጎት (LANGUAGE & SPECIAL NEEDS)
  // --------------------------------------------------------------------------
  Widget _buildSpecialNeedsModule(BuildContext context, FellowshipState state, bool isAudit) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Multilingual & Sign-Language Services', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
              Icon(Icons.translate_outlined, color: primaryAccent, size: 20),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Translation rosters for Afaan Oromoo, Tigrinya, English, and Geez liturgical texts, plus sign-language interpreter duty shifts.',
            style: TextStyle(fontSize: 11, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // DEPARTMENT 9: እቅድና ክትትል (PLANNING & MONITORING)
  // --------------------------------------------------------------------------
  Widget _buildPlanningModule(BuildContext context, FellowshipState state, bool isAudit) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Semester Strategy & Ministry OKRs', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
              Icon(Icons.pie_chart_outline, color: primaryAccent, size: 20),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Quarterly milestone progress tracking, committee performance benchmarks, and end-of-term evaluations.',
            style: TextStyle(fontSize: 11, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // DEPARTMENT 10: ኦዲትና ኢንስፔክሽን (AUDIT & INSPECTION)
  // --------------------------------------------------------------------------
  Widget _buildAuditModule(BuildContext context, FellowshipState state) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5A65E).withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF5A65E).withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.fact_check_outlined, color: Color(0xFFF5A65E), size: 22),
              SizedBox(width: 10),
              Text('Audit & Inspection Access Log', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFF5A65E))),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'You have read-only inspection access across all 10 fellowship sub-committees to verify transparency, constitution compliance, and asset management.',
            style: TextStyle(fontSize: 11, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary, height: 1.3),
          ),
        ],
      ),
    );
  }

  Widget _buildGenericDepartmentModule(BuildContext context, FellowshipState state, String deptId) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Text(
        'Department active and operational.',
        style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary),
      ),
    );
  }

  // ============================================================================
  // TAB 2: SCOPED VOLUNTEER APPLICATIONS (THIS DEPT ONLY)
  // ============================================================================
  Widget _buildDepartmentApplicationsTab(
    BuildContext context,
    FellowshipState state,
    String deptId,
    List<VolunteerApplicationModel> pendingApps,
    bool isAudit,
  ) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;

    if (pendingApps.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline, color: AppTheme.emerald, size: 48),
            const SizedBox(height: 12),
            Text(
              'No pending volunteer applications for ${FellowshipDepartmentConstants.getNameAmharic(deptId)}.',
              style: TextStyle(color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: pendingApps.length,
      itemBuilder: (ctx, index) {
        final app = pendingApps[index];
        return InteractiveFellowshipCard(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          color: theme.cardTheme.color ?? theme.colorScheme.surface,
          borderColor: theme.dividerColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: primaryAccent.withOpacity(0.12),
                    child: Text(
                      app.studentName.isNotEmpty ? app.studentName[0] : 'V',
                      style: TextStyle(color: primaryAccent, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(app.studentName, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                        Text('B.N. ${app.studentBaptismalName} • Year ${app.studentYear} • ${app.studentDept}', style: TextStyle(fontSize: 11, color: primaryAccent)),
                      ],
                    ),
                  ),
                  if (app.choirWing != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: primaryAccent.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        app.choirWing == ChoirWingType.mezmur ? 'Mezmur' : 'Fine Arts',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: primaryAccent),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Motivation / Ministry Reason:',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary),
              ),
              const SizedBox(height: 2),
              Text(
                app.reason,
                style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface, fontStyle: FontStyle.italic),
              ),
              if (!isAudit) ...[
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        state.rejectVolunteerApplication(app.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Application from ${app.studentName} rejected.')),
                        );
                      },
                      style: OutlinedButton.styleFrom(foregroundColor: AppTheme.crimson),
                      child: const Text('Reject', style: TextStyle(fontSize: 11)),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        state.approveVolunteerApplication(app.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${app.studentName} accepted into ${FellowshipDepartmentConstants.getNameAmharic(deptId)}!')),
                        );
                      },
                      icon: const Icon(Icons.check, size: 14, color: Colors.white),
                      label: const Text('Accept Volunteer', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  // ============================================================================
  // TAB 3: ACTIVE VOLUNTEERS ROSTER
  // ============================================================================
  Widget _buildDepartmentRosterTab(
    BuildContext context,
    FellowshipState state,
    String deptId,
    List<DepartmentMemberModel> members,
    bool isAudit,
  ) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;

    if (members.isEmpty) {
      return Center(
        child: Text(
          'No active volunteers in this department roster.',
          style: TextStyle(color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary, fontSize: 13),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: members.length,
      itemBuilder: (ctx, index) {
        final member = members[index];
        return InteractiveFellowshipCard(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          color: theme.cardTheme.color ?? theme.colorScheme.surface,
          borderColor: theme.dividerColor,
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                child: Text(
                  member.studentName.isNotEmpty ? member.studentName[0] : 'S',
                  style: TextStyle(color: primaryAccent, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(member.studentName, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                    Text('B.N. ${member.studentBaptismalName} • Year ${member.studentYear}', style: TextStyle(fontSize: 11, color: primaryAccent)),
                    Text('${member.studentDept} • Role: ${member.roleInDepartment}', style: TextStyle(fontSize: 10, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.phone_outlined, size: 18),
                color: primaryAccent,
                onPressed: () {
                  HapticFeedback.selectionClick();
                  state.launchCall(member.phoneNumber);
                },
              ),
              IconButton(
                icon: const Icon(Icons.telegram, size: 20),
                color: const Color(0xFF38A3E5),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  state.launchTelegram(member.phoneNumber);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // --------------------------------------------------------------------------
  // MODALS & DIALOGS (INTERACTIVE PILGRIMAGE & CHARITY DETAILS & EDIT/DELETE)
  // --------------------------------------------------------------------------

  // 1. Add Pilgrimage Trip Modal
  void _openAddPilgrimageTripModal(BuildContext context, FellowshipState state) {
    final titleCtrl = TextEditingController();
    final monasteryCtrl = TextEditingController();
    final dateCtrl = TextEditingController(text: 'Ginbot 21 (May 29)');
    final feeCtrl = TextEditingController(text: '350');
    final seatsCtrl = TextEditingController(text: '90');
    final descCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 20, left: 20, right: 20, top: 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Add New Pilgrimage Trip • አዲስ መንፈሳዊ ጉዞ', style: TextStyle(fontFamily: 'serif', fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                const SizedBox(height: 14),
                TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Trip Title (e.g. ወልዲባ ገዳም መንፈሳዊ ጉዞ)')),
                const SizedBox(height: 10),
                TextField(controller: monasteryCtrl, decoration: const InputDecoration(labelText: 'Destination Monastery / Church')),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: TextField(controller: feeCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Fee per Seat (ETB)'))),
                    const SizedBox(width: 10),
                    Expanded(child: TextField(controller: seatsCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Total Seat Capacity'))),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(controller: dateCtrl, decoration: const InputDecoration(labelText: 'Departure Date & Schedule')),
                const SizedBox(height: 10),
                TextField(controller: descCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Itinerary & Guidelines')),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (titleCtrl.text.trim().isEmpty) return;
                      final fee = double.tryParse(feeCtrl.text.trim()) ?? 350.0;
                      final newTrip = PilgrimageTripModel(
                        id: 'trip-${DateTime.now().millisecondsSinceEpoch}',
                        title: titleCtrl.text.trim(),
                        destination: monasteryCtrl.text.trim().isEmpty ? 'Holy Monastery' : monasteryCtrl.text.trim(),
                        departureDate: DateTime.now().add(const Duration(days: 14)),
                        returnDate: DateTime.now().add(const Duration(days: 15)),
                        departurePoint: 'WCU Campus Main Gate',
                        feeAmount: fee,
                        isFree: fee <= 0,
                        telebirrNumber: '+251911223344',
                        telebirrAccountName: 'WCU Orthodox Fellowship',
                        cbeAccountNumber: '1000234567890',
                        cbeAccountName: 'WCU Orthodox Tewahedo Fellowship',
                        totalSeats: int.tryParse(seatsCtrl.text.trim()) ?? 90,
                        bookedSeats: 0,
                        itinerary: [descCtrl.text.trim().isNotEmpty ? descCtrl.text.trim() : 'Liturgy & spiritual blessing'],
                        packingList: ['Netela (ነጠላ)', 'Prayer Book', 'Student Fellowship ID'],
                        coordinatorName: state.currentUser.fullName,
                        coordinatorPhone: state.currentUser.phoneNumber,
                      );
                      state.addPilgrimageTrip(newTrip);
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Pilgrimage Trip "${newTrip.title}" created successfully!')));
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary),
                    child: const Text('Publish Pilgrimage Trip', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 2. Edit Pilgrimage Trip Modal
  void _openEditTripModal(BuildContext context, FellowshipState state, PilgrimageTripModel trip) {
    final titleCtrl = TextEditingController(text: trip.title);
    final monasteryCtrl = TextEditingController(text: trip.destination);
    final feeCtrl = TextEditingController(text: trip.feeAmount.toStringAsFixed(0));
    final seatsCtrl = TextEditingController(text: trip.totalSeats.toString());
    final dateCtrl = TextEditingController(text: '${trip.departureDate.year}-${trip.departureDate.month}-${trip.departureDate.day}');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 20, left: 20, right: 20, top: 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Edit Pilgrimage Details • የጉዞ መረጃ ማስተካከያ', style: TextStyle(fontFamily: 'serif', fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                const SizedBox(height: 14),
                TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Trip Title')),
                const SizedBox(height: 10),
                TextField(controller: monasteryCtrl, decoration: const InputDecoration(labelText: 'Destination Monastery')),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: TextField(controller: feeCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Fee (ETB)'))),
                    const SizedBox(width: 10),
                    Expanded(child: TextField(controller: seatsCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Total Seats'))),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(controller: dateCtrl, decoration: const InputDecoration(labelText: 'Departure Date')),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      final updated = trip.copyWith(
                        title: titleCtrl.text.trim(),
                        destination: monasteryCtrl.text.trim(),
                        feeAmount: double.tryParse(feeCtrl.text.trim()) ?? trip.feeAmount,
                        totalSeats: int.tryParse(seatsCtrl.text.trim()) ?? trip.totalSeats,
                      );
                      state.updatePilgrimageTrip(updated);
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Trip "${updated.title}" updated.')));
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary),
                    child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 3. Register Pilgrim Student Modal (Add User Pilgrimage Details)
  void _openAddPilgrimStudentModal(BuildContext context, FellowshipState state) {
    if (state.pilgrimageTrips.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add a pilgrimage trip first!')));
      return;
    }

    String selectedTripId = state.pilgrimageTrips.first.id;
    final nameCtrl = TextEditingController();
    final baptismalCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final deptCtrl = TextEditingController(text: 'Engineering');
    final refCtrl = TextEditingController(text: 'TB-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}');
    PaymentMethodType selectedMethod = PaymentMethodType.telebirr;
    int busNo = 1;
    int seatNo = 12;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setMState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 20, left: 20, right: 20, top: 20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Register Pilgrim Student • ተጓዥ መመዝገቢያ', style: TextStyle(fontFamily: 'serif', fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: selectedTripId,
                      items: state.pilgrimageTrips.map((t) => DropdownMenuItem(value: t.id, child: Text(t.title, maxLines: 1, overflow: TextOverflow.ellipsis))).toList(),
                      onChanged: (val) {
                        if (val != null) setMState(() => selectedTripId = val);
                      },
                      decoration: const InputDecoration(labelText: 'Select Pilgrimage Trip'),
                    ),
                    const SizedBox(height: 10),
                    TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Student Full Name')),
                    const SizedBox(height: 10),
                    TextField(controller: baptismalCtrl, decoration: const InputDecoration(labelText: 'Baptismal Name (የክርስትና ስም)')),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone Number'))),
                        const SizedBox(width: 10),
                        Expanded(child: TextField(controller: deptCtrl, decoration: const InputDecoration(labelText: 'Academic Dept'))),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: busNo,
                            items: [1, 2, 3, 4, 5].map((b) => DropdownMenuItem(value: b, child: Text('Bus #$b'))).toList(),
                            onChanged: (val) {
                              if (val != null) setMState(() => busNo = val);
                            },
                            decoration: const InputDecoration(labelText: 'Assigned Bus'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: seatNo,
                            items: List.generate(50, (i) => i + 1).map((s) => DropdownMenuItem(value: s, child: Text('Seat #$s'))).toList(),
                            onChanged: (val) {
                              if (val != null) setMState(() => seatNo = val);
                            },
                            decoration: const InputDecoration(labelText: 'Seat Number'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<PaymentMethodType>(
                      value: selectedMethod,
                      items: [PaymentMethodType.telebirr, PaymentMethodType.cbeBirr, PaymentMethodType.cash, PaymentMethodType.free]
                          .map((m) => DropdownMenuItem(value: m, child: Text(m.displayName)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setMState(() => selectedMethod = val);
                      },
                      decoration: const InputDecoration(labelText: 'Payment Method'),
                    ),
                    const SizedBox(height: 10),
                    TextField(controller: refCtrl, decoration: const InputDecoration(labelText: 'Transaction Ref / Receipt Code')),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (nameCtrl.text.trim().isEmpty) return;
                          final trip = state.pilgrimageTrips.firstWhere((t) => t.id == selectedTripId);
                          final newReg = TripRegistrationModel(
                            id: 'reg-${DateTime.now().millisecondsSinceEpoch}',
                            tripId: trip.id,
                            tripTitle: trip.title,
                            studentId: 'stud-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
                            studentName: nameCtrl.text.trim(),
                            studentBaptismalName: baptismalCtrl.text.trim().isEmpty ? 'Walda Maryam' : baptismalCtrl.text.trim(),
                            studentPhone: phoneCtrl.text.trim().isEmpty ? '0911002233' : phoneCtrl.text.trim(),
                            department: deptCtrl.text.trim(),
                            academicYear: 3,
                            busNumber: busNo,
                            seatNumber: seatNo,
                            feeAmount: trip.feeAmount,
                            isFree: trip.isFree,
                            paymentMethod: selectedMethod,
                            transactionReference: refCtrl.text.trim(),
                            paymentStatus: TripPaymentStatus.verified,
                            qrTicketCode: 'PILGRIM-${trip.id.substring(0, 4).toUpperCase()}-${DateTime.now().millisecondsSinceEpoch.toString().substring(9)}',
                            registeredAt: DateTime.now(),
                          );
                          state.addPilgrimRegistration(newReg);
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Pilgrim ${newReg.studentName} registered for Bus #$busNo Seat #$seatNo!')));
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary),
                        child: const Text('Confirm Pilgrim Registration', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
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

  // 4. Edit Pilgrim Student Modal (Change Seat, Bus, Payment Status)
  void _openEditPilgrimStudentModal(BuildContext context, FellowshipState state, TripRegistrationModel reg) {
    final nameCtrl = TextEditingController(text: reg.studentName);
    final baptismalCtrl = TextEditingController(text: reg.studentBaptismalName);
    final phoneCtrl = TextEditingController(text: reg.studentPhone);
    final refCtrl = TextEditingController(text: reg.transactionReference);
    int busNo = reg.busNumber;
    int seatNo = reg.seatNumber;
    TripPaymentStatus status = reg.paymentStatus;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setMState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 20, left: 20, right: 20, top: 20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Edit Pilgrim Passenger & Seat • ተጓዥ ማስተካከያ', style: TextStyle(fontFamily: 'serif', fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                    const SizedBox(height: 14),
                    TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Student Name')),
                    const SizedBox(height: 10),
                    TextField(controller: baptismalCtrl, decoration: const InputDecoration(labelText: 'Baptismal Name')),
                    const SizedBox(height: 10),
                    TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone Number')),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: busNo,
                            items: [1, 2, 3, 4, 5].map((b) => DropdownMenuItem(value: b, child: Text('Bus #$b'))).toList(),
                            onChanged: (val) {
                              if (val != null) setMState(() => busNo = val);
                            },
                            decoration: const InputDecoration(labelText: 'Bus #'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: seatNo,
                            items: List.generate(50, (i) => i + 1).map((s) => DropdownMenuItem(value: s, child: Text('Seat #$s'))).toList(),
                            onChanged: (val) {
                              if (val != null) setMState(() => seatNo = val);
                            },
                            decoration: const InputDecoration(labelText: 'Seat #'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<TripPaymentStatus>(
                      value: status,
                      items: [TripPaymentStatus.verified, TripPaymentStatus.pendingVerification, TripPaymentStatus.rejected, TripPaymentStatus.free]
                          .map((s) => DropdownMenuItem(value: s, child: Text(s.displayName)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setMState(() => status = val);
                      },
                      decoration: const InputDecoration(labelText: 'Payment Status'),
                    ),
                    const SizedBox(height: 10),
                    TextField(controller: refCtrl, decoration: const InputDecoration(labelText: 'Transaction Ref')),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          final updated = reg.copyWith(
                            studentName: nameCtrl.text.trim(),
                            studentBaptismalName: baptismalCtrl.text.trim(),
                            studentPhone: phoneCtrl.text.trim(),
                            busNumber: busNo,
                            seatNumber: seatNo,
                            paymentStatus: status,
                            transactionReference: refCtrl.text.trim(),
                          );
                          state.updatePilgrimRegistration(updated);
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Passenger record for ${updated.studentName} updated.')));
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary),
                        child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
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

  // 5. Pilgrim Digital E-Ticket & Receipt Modal
  void _openPilgrimTicketModal(BuildContext context, FellowshipState state, TripRegistrationModel reg) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.confirmation_number_outlined, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            const Expanded(child: Text('Pilgrim E-Ticket Pass', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.qr_code_2, size: 90, color: Colors.black),
                      const SizedBox(height: 4),
                      Text(reg.qrTicketCode, style: const TextStyle(fontSize: 9, fontFamily: 'monospace', color: Colors.black87, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildTicketDetailRow('Passenger:', reg.studentName),
              _buildTicketDetailRow('Baptismal Name:', reg.studentBaptismalName),
              _buildTicketDetailRow('Trip Title:', reg.tripTitle),
              _buildTicketDetailRow('Bus & Seat:', 'Bus #${reg.busNumber} • Seat #${reg.seatNumber}'),
              _buildTicketDetailRow('Fare Paid:', '${reg.feeAmount.toStringAsFixed(0)} ETB'),
              _buildTicketDetailRow('Payment Channel:', reg.paymentMethod.displayName),
              _buildTicketDetailRow('Transaction Ref:', reg.transactionReference),
              _buildTicketDetailRow('Status:', reg.paymentStatus.displayName),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  // 6. Add Charity Campaign Modal
  void _openAddCharityCampaignModal(BuildContext context, FellowshipState state) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final targetCtrl = TextEditingController(text: '25000');
    String category = 'Student Mutual Aid';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setMState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 20, left: 20, right: 20, top: 20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Add Charity Campaign • አዲስ የበጎ አድራጎት ፕሮጀክት', style: TextStyle(fontFamily: 'serif', fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                    const SizedBox(height: 14),
                    TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Campaign Title (e.g. የተማሪዎች ደብተርና እስክሪብቶ ድጋፍ)')),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: category,
                      items: ['Student Mutual Aid', 'Orphanage Outreach', 'Hospital Visits', 'Church Construction', 'Emergency Food Aid']
                          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setMState(() => category = val);
                      },
                      decoration: const InputDecoration(labelText: 'Category'),
                    ),
                    const SizedBox(height: 10),
                    TextField(controller: targetCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Target Budget (ETB)')),
                    const SizedBox(height: 10),
                    TextField(controller: descCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Description & Beneficiary Plan')),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (titleCtrl.text.trim().isEmpty) return;
                          final newCamp = CharityCampaignModel(
                            id: 'camp-${DateTime.now().millisecondsSinceEpoch}',
                            title: titleCtrl.text.trim(),
                            description: descCtrl.text.trim(),
                            targetAmount: double.tryParse(targetCtrl.text.trim()) ?? 25000.0,
                            raisedAmount: 0.0,
                            donorsCount: 0,
                            deadline: DateTime.now().add(const Duration(days: 30)),
                            category: category,
                          );
                          state.addCharityCampaign(newCamp);
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Charity Campaign "${newCamp.title}" published!')));
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
                        child: const Text('Launch Campaign', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
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

  // 7. Edit Charity Campaign Modal
  void _openEditCharityCampaignModal(BuildContext context, FellowshipState state, CharityCampaignModel camp) {
    final titleCtrl = TextEditingController(text: camp.title);
    final targetCtrl = TextEditingController(text: camp.targetAmount.toStringAsFixed(0));
    final descCtrl = TextEditingController(text: camp.description);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 20, left: 20, right: 20, top: 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Edit Charity Goal • የበጎ አድራጎት ማስተካከያ', style: TextStyle(fontFamily: 'serif', fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                const SizedBox(height: 14),
                TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Campaign Title')),
                const SizedBox(height: 10),
                TextField(controller: targetCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Target Goal (ETB)')),
                const SizedBox(height: 10),
                TextField(controller: descCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Description')),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      final updated = CharityCampaignModel(
                        id: camp.id,
                        title: titleCtrl.text.trim(),
                        description: descCtrl.text.trim(),
                        targetAmount: double.tryParse(targetCtrl.text.trim()) ?? camp.targetAmount,
                        raisedAmount: camp.raisedAmount,
                        donorsCount: camp.donorsCount,
                        deadline: camp.deadline,
                        category: camp.category,
                      );
                      state.updateCharityCampaign(updated);
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Campaign "${updated.title}" updated.')));
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
                    child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 8. Record Donation / Dues Modal (Add Inflow)
  void _openRecordDonationModal(BuildContext context, FellowshipState state) {
    final nameCtrl = TextEditingController();
    final amountCtrl = TextEditingController(text: '500');
    final purposeCtrl = TextEditingController(text: 'Monthly Fellowship Dues');
    final refCtrl = TextEditingController(text: 'DON-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}');
    PaymentMethodType method = PaymentMethodType.telebirr;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setMState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 20, left: 20, right: 20, top: 20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Record Donation / Dues • የልገሳ መመዝገቢያ', style: TextStyle(fontFamily: 'serif', fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                    const SizedBox(height: 14),
                    TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Donor / Fellow Name')),
                    const SizedBox(height: 10),
                    TextField(controller: amountCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Amount (ETB)')),
                    const SizedBox(height: 10),
                    TextField(controller: purposeCtrl, decoration: const InputDecoration(labelText: 'Purpose / Fund Designation')),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<PaymentMethodType>(
                      value: method,
                      items: [PaymentMethodType.telebirr, PaymentMethodType.cbeBirr, PaymentMethodType.cash]
                          .map((m) => DropdownMenuItem(value: m, child: Text(m.displayName)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setMState(() => method = val);
                      },
                      decoration: const InputDecoration(labelText: 'Payment Method'),
                    ),
                    const SizedBox(height: 10),
                    TextField(controller: refCtrl, decoration: const InputDecoration(labelText: 'Receipt / Bank Reference')),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (nameCtrl.text.trim().isEmpty) return;
                          state.submitDuesPayment(
                            amount: double.tryParse(amountCtrl.text.trim()) ?? 500.0,
                            purpose: purposeCtrl.text.trim(),
                            paymentMethod: method,
                            transactionReference: refCtrl.text.trim(),
                          );
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Contribution of ${amountCtrl.text} ETB recorded for ${nameCtrl.text.trim()}!')));
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
                        child: const Text('Save Contribution', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
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

  // 9. Disburse Aid Grant Modal (Add Outflow)
  void _openDisburseAidModal(BuildContext context, FellowshipState state) {
    final beneficiaryCtrl = TextEditingController();
    final amountCtrl = TextEditingController(text: '800');
    final purposeCtrl = TextEditingController(text: 'Cafeteria & Meal Subsidy');
    final voucherCtrl = TextEditingController(text: 'DISB-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}');
    final notesCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 20, left: 20, right: 20, top: 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Disburse Charity Aid • ድጋፍ መስጫ ቫውቸር', style: TextStyle(fontFamily: 'serif', fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.crimson)),
                const SizedBox(height: 14),
                TextField(controller: beneficiaryCtrl, decoration: const InputDecoration(labelText: 'Beneficiary Student Name (e.g. Dawit Tadesse)')),
                const SizedBox(height: 10),
                TextField(controller: amountCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Disbursed Amount (ETB)')),
                const SizedBox(height: 10),
                TextField(controller: purposeCtrl, decoration: const InputDecoration(labelText: 'Assistance Category / Need Reason')),
                const SizedBox(height: 10),
                TextField(controller: voucherCtrl, decoration: const InputDecoration(labelText: 'Voucher Reference ID')),
                const SizedBox(height: 10),
                TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'Notes & Receipt Reference')),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (beneficiaryCtrl.text.trim().isEmpty) return;
                      final disb = CharityDisbursementModel(
                        id: 'disb-${DateTime.now().millisecondsSinceEpoch}',
                        beneficiaryName: beneficiaryCtrl.text.trim(),
                        assistanceType: purposeCtrl.text.trim(),
                        amount: double.tryParse(amountCtrl.text.trim()) ?? 800.0,
                        voucherReference: voucherCtrl.text.trim(),
                        approvedBy: state.currentUser.fullName,
                        disbursedAt: DateTime.now(),
                        notes: notesCtrl.text.trim(),
                      );
                      state.addCharityDisbursement(disb);
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Aid of ${disb.amount.toStringAsFixed(0)} ETB disbursed for ${disb.beneficiaryName}!')));
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.crimson),
                    child: const Text('Confirm Disbursement', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmDeleteDialog(BuildContext context, {required String title, required String message, required VoidCallback onConfirm}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              HapticFeedback.mediumImpact();
              onConfirm();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.crimson),
            child: const Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // HELPER WIDGETS
  // --------------------------------------------------------------------------
  Widget _buildFinancialSubTile(BuildContext context, {required String label, required String amount, required Color color}) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            amount,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 9, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMiniBadge(BuildContext context, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  Widget _buildTicketDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black87)),
          ),
        ],
      ),
    );
  }

  Widget _buildActionChip(BuildContext context, IconData icon, String label) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: primaryAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: primaryAccent.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: primaryAccent),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryAccent),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleRow(BuildContext context, String time, String desc) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: primaryAccent.withOpacity(0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(time, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: primaryAccent)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(desc, style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface)),
        ),
      ],
    );
  }
}
