part of '../coordinator_hub_screen.dart';

extension DeptMemberCareModuleExt on _CoordinatorHubScreenState {
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
}
