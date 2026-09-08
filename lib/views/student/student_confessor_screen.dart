import 'package:flutter/material.dart';
import '../../models/app_models.dart';
import '../../state/fellowship_state.dart';
import '../../theme/app_theme.dart';

class StudentConfessorScreen extends StatefulWidget {
  final FellowshipState state;

  const StudentConfessorScreen({super.key, required this.state});

  @override
  State<StudentConfessorScreen> createState() => _StudentConfessorScreenState();
}

class _StudentConfessorScreenState extends State<StudentConfessorScreen> {
  int _activeTab = 0; // 0: Priests & Book, 1: My Appointments & Checklist, 2: Anonymous Q&A

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Father Confessor • የንስሐ አባት'),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Segmented Navigation Header
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: theme.cardTheme.color ?? theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Row(
              children: [
                Expanded(child: _buildNavButton(context, 'Fathers & Booking', Icons.person_pin, 0)),
                Expanded(child: _buildNavButton(context, 'My Prep & Checklist', Icons.checklist_rtl, 1)),
                Expanded(child: _buildNavButton(context, 'Spiritual Q&A', Icons.help_outline, 2)),
              ],
            ),
          ),

          Expanded(
            child: _activeTab == 0
                ? _buildFathersTab(context, state)
                : _activeTab == 1
                    ? _buildAppointmentsAndChecklistTab(context, state)
                    : _buildAnonymousQaTab(context, state),
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton(BuildContext context, String title, IconData icon, int index) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final isSelected = _activeTab == index;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? primaryAccent.withOpacity(0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? Border.all(color: primaryAccent.withOpacity(0.5)) : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: isSelected ? primaryAccent : (theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary)),
            const SizedBox(height: 3),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? primaryAccent : (theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------
  // TAB 0: CONFESSOR FATHERS & BOOKING
  // ----------------------------------------------------
  Widget _buildFathersTab(BuildContext context, FellowshipState state) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;

    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        // Intro Banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.surfaceContainerHighest,
                theme.cardTheme.color ?? theme.colorScheme.surface,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: primaryAccent.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.shield_outlined, color: primaryAccent, size: 30),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Spiritual Fatherhood (የንስሐ አባትነት)',
                      style: TextStyle(fontFamily: 'serif', fontSize: 15, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Schedule confidential 1-on-1 confession, spiritual counseling, and communion absolution with campus-assigned clergy.',
                      style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary, height: 1.3),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        Text(
          'CAMPUS CONFESSOR FATHERS',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7) ?? AppTheme.textTertiary, letterSpacing: 1.5),
        ),
        const SizedBox(height: 10),

        ...state.confessorFathers.map((father) {
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
                      child: Icon(Icons.person, color: primaryAccent, size: 30),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            father.fullName,
                            style: TextStyle(
                              fontFamily: 'serif',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            father.clericalTitle,
                            style: TextStyle(fontSize: 12, color: primaryAccent, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            father.churchName,
                            style: TextStyle(fontSize: 11, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.location_on, color: primaryAccent, size: 13),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  father.meetingVenue,
                                  style: TextStyle(fontSize: 11, color: primaryAccent, fontWeight: FontWeight.w600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  father.bio,
                  style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary, height: 1.4),
                ),
                const SizedBox(height: 14),

                // Availability Pills
                Text('AVAILABLE DAYS:', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7) ?? AppTheme.textTertiary, letterSpacing: 1.0)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    ...father.availableDays.map((d) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: theme.dividerColor),
                          ),
                          child: Text(d, style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurface)),
                        )),
                  ],
                ),

                const SizedBox(height: 16),
                Divider(color: theme.dividerColor),
                const SizedBox(height: 10),

                // Action Buttons
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.phone_outlined, color: primaryAccent, size: 18),
                            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                            padding: const EdgeInsets.all(8),
                            onPressed: () => state.launchCall(father.phoneNumber),
                          ),
                          IconButton(
                            icon: Icon(Icons.sms_outlined, color: primaryAccent, size: 18),
                            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                            padding: const EdgeInsets.all(8),
                            onPressed: () => state.launchSms(father.phoneNumber, body: 'Selam Abba, I am requesting a spiritual confession appointment.'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _openBookingDialog(context, father),
                        icon: Icon(Icons.calendar_month, size: 15, color: isDark ? Colors.black : Colors.white),
                        label: Text(
                          'Book Appointment',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: isDark ? Colors.black : Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryAccent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
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
  // TAB 1: MY APPOINTMENTS & COMMUNION PREPARATION
  // ----------------------------------------------------
  Widget _buildAppointmentsAndChecklistTab(BuildContext context, FellowshipState state) {
    final theme = Theme.of(context);
    final myAppts = state.myConfessionAppointments;

    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Text(
          'MY CONFESSION APPOINTMENTS',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7) ?? AppTheme.textTertiary, letterSpacing: 1.5),
        ),
        const SizedBox(height: 10),

        if (myAppts.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.cardTheme.color ?? theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Center(
              child: Text(
                'No appointments scheduled yet. Book with a spiritual father above.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary),
              ),
            ),
          )
        else
          ...myAppts.map((appt) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardTheme.color ?? theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: appt.status.color.withOpacity(0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          appt.fatherName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: appt.status.color.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: appt.status.color.withOpacity(0.6)),
                        ),
                        child: Text(
                          appt.status.displayName,
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: appt.status.color),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text('Topic: ${appt.topic}', style: TextStyle(fontSize: 12, color: theme.colorScheme.primary)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.schedule, size: 14, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${appt.scheduledDate.year}-${appt.scheduledDate.month}-${appt.scheduledDate.day} • ${appt.timeSlot}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary),
                        ),
                      ),
                    ],
                  ),
                  if (appt.notes != null && appt.notes!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('Father\'s note: ${appt.notes}', style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface)),
                    ),
                  ],
                  if (appt.status == ConfessionAppointmentStatus.pending || appt.status == ConfessionAppointmentStatus.confirmed) ...[
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          state.cancelConfessionAppointment(appt.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: const Text('Appointment cancelled'), backgroundColor: theme.cardTheme.color ?? theme.colorScheme.surface),
                          );
                        },
                        child: const Text('Cancel Appointment', style: TextStyle(color: Color(0xFFEF4444), fontSize: 11)),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),

        const SizedBox(height: 24),

        // Holy Communion Preparation Checklist
        Text(
          'HOLY COMMUNION PREPARATION CHECKLIST (ቅድመ ዝግጅት)',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7) ?? AppTheme.textTertiary, letterSpacing: 1.5),
        ),
        const SizedBox(height: 10),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardTheme.color ?? theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Column(
            children: state.communionChecklist.map((item) {
              return CheckboxListTile(
                value: item.isChecked,
                activeColor: const Color(0xFF10B981),
                checkColor: Colors.black,
                contentPadding: EdgeInsets.zero,
                onChanged: (_) => setState(() => state.toggleCommunionItem(item.id)),
                title: Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: item.isChecked ? const Color(0xFF10B981) : theme.colorScheme.onSurface,
                    decoration: item.isChecked ? TextDecoration.none : null,
                  ),
                ),
                subtitle: Text(
                  item.description,
                  style: TextStyle(fontSize: 11, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ----------------------------------------------------
  // TAB 2: ANONYMOUS SPIRITUAL Q&A
  // ----------------------------------------------------
  Widget _buildAnonymousQaTab(BuildContext context, FellowshipState state) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;

    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        // Ask Anonymous Question Button
        ElevatedButton.icon(
          onPressed: () => _openAskQuestionDialog(context),
          icon: Icon(Icons.lock_outline, color: isDark ? Colors.black : Colors.white, size: 18),
          label: Text('Ask Confidential / Anonymous Question', style: TextStyle(color: isDark ? Colors.black : Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryAccent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),

        const SizedBox(height: 20),

        Text(
          'ANSWERED THEOLOGICAL & MORAL QUESTIONS',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7) ?? AppTheme.textTertiary, letterSpacing: 1.5),
        ),
        const SizedBox(height: 10),

        ...state.spiritualQuestions.map((q) {
          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardTheme.color ?? theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: primaryAccent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    q.category,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: primaryAccent),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Q: ${q.questionText}',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface, height: 1.3),
                ),
                const SizedBox(height: 12),
                if (q.isAnswered && q.answerText != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: primaryAccent.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.verified, color: primaryAccent, size: 14),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Answered by ${q.answeredBy ?? "Campus Clergy"}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryAccent),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          q.answerText!,
                          style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Text('Pending answer from Confession Fathers committee...', style: TextStyle(fontSize: 11, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7) ?? AppTheme.textTertiary)),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }

  void _openBookingDialog(BuildContext context, ConfessorFatherModel father) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;

    String selectedSlot = father.availableTimeSlots.first;
    String selectedTopic = 'General Confession (ምሥጢረ ንስሐ)';
    DateTime selectedDate = DateTime.now().add(const Duration(days: 2));
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: theme.cardTheme.color ?? theme.colorScheme.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text('Book with ${father.fullName}', style: TextStyle(fontFamily: 'serif', fontSize: 16, color: primaryAccent, fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: primaryAccent.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.location_on, color: primaryAccent, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Meeting Place:\n${father.meetingVenue}',
                              style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface, fontWeight: FontWeight.w600, height: 1.3),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text('Select Topic:', style: TextStyle(fontSize: 11, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary)),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      value: selectedTopic,
                      dropdownColor: theme.cardTheme.color ?? theme.colorScheme.surface,
                      items: [
                        'General Confession (ምሥጢረ ንስሐ)',
                        'Communion Preparation (የቁርባን ዝግጅት)',
                        'Spiritual Counseling (የመንፈሳዊ ሕይወት ምክር)',
                        'Campus Moral Challenges (የግቢ ኑሮ ፈተናዎች)',
                      ].map((t) => DropdownMenuItem(value: t, child: Text(t, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface)))).toList(),
                      onChanged: (val) => setDialogState(() => selectedTopic = val!),
                    ),
                    const SizedBox(height: 12),
                    Text('Select Time Slot:', style: TextStyle(fontSize: 11, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary)),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      value: selectedSlot,
                      dropdownColor: theme.cardTheme.color ?? theme.colorScheme.surface,
                      items: father.availableTimeSlots.map((s) => DropdownMenuItem(value: s, child: Text(s, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface)))).toList(),
                      onChanged: (val) => setDialogState(() => selectedSlot = val!),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: noteController,
                      decoration: const InputDecoration(
                        labelText: 'Optional Note for Abba',
                        hintText: 'e.g. Preparing for Sunday Holy Communion',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('Cancel', style: TextStyle(color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary)),
                ),
                ElevatedButton(
                  onPressed: () {
                    widget.state.bookConfessionAppointment(
                      fatherId: father.id,
                      scheduledDate: selectedDate,
                      timeSlot: selectedSlot,
                      topic: selectedTopic,
                      notes: noteController.text.trim().isNotEmpty ? noteController.text.trim() : null,
                    );
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: const Text('Appointment request sent to Confession Father'), backgroundColor: theme.cardTheme.color ?? theme.colorScheme.surface),
                    );
                    setState(() => _activeTab = 1);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: primaryAccent),
                  child: Text('Confirm Booking', style: TextStyle(color: isDark ? Colors.black : Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _openAskQuestionDialog(BuildContext context) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;

    final qController = TextEditingController();
    String category = 'Campus Life & Morals';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: theme.cardTheme.color ?? theme.colorScheme.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text('Ask Confidential Question', style: TextStyle(fontFamily: 'serif', fontSize: 16, color: primaryAccent, fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Your identity and name are never revealed. The question will be reviewed by the fellowship clergy committee.',
                    style: TextStyle(fontSize: 11, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: category,
                    dropdownColor: theme.cardTheme.color ?? theme.colorScheme.surface,
                    items: ['Campus Life & Morals', 'Fasting & Prayer Rules', 'Theology & Dogma', 'Sacraments & Canon']
                        .map((c) => DropdownMenuItem(value: c, child: Text(c, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface))))
                        .toList(),
                    onChanged: (val) => setDialogState(() => category = val!),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: qController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Your Question',
                      hintText: 'Type your spiritual or doctrinal question here...',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('Cancel', style: TextStyle(color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary)),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (qController.text.trim().isEmpty) return;
                    widget.state.submitAnonymousQuestion(
                      questionText: qController.text.trim(),
                      category: category,
                    );
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: const Text('Confidential question submitted'), backgroundColor: theme.cardTheme.color ?? theme.colorScheme.surface),
                    );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: primaryAccent),
                  child: Text('Submit', style: TextStyle(color: isDark ? Colors.black : Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
