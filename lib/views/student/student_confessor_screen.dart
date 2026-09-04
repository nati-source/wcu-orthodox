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

    return Scaffold(
      backgroundColor: AppTheme.primaryBg,
      appBar: AppBar(
        title: const Text('Father Confessor • የንስሐ አባት'),
        backgroundColor: AppTheme.primaryBg,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Segmented Navigation Header
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppTheme.secondaryBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderMuted),
            ),
            child: Row(
              children: [
                Expanded(child: _buildNavButton('Fathers & Booking', Icons.person_pin, 0)),
                Expanded(child: _buildNavButton('My Prep & Checklist', Icons.checklist_rtl, 1)),
                Expanded(child: _buildNavButton('Spiritual Q&A', Icons.help_outline, 2)),
              ],
            ),
          ),

          Expanded(
            child: _activeTab == 0
                ? _buildFathersTab(state)
                : _activeTab == 1
                    ? _buildAppointmentsAndChecklistTab(state)
                    : _buildAnonymousQaTab(state),
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton(String title, IconData icon, int index) {
    final isSelected = _activeTab == index;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.surfaceElevated : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? Border.all(color: AppTheme.goldAccent.withOpacity(0.5)) : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: isSelected ? AppTheme.goldLight : AppTheme.textSecondary),
            const SizedBox(height: 3),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : AppTheme.textSecondary,
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
  Widget _buildFathersTab(FellowshipState state) {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        // Intro Banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2B3446), Color(0xFF1B2332)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.goldAccent.withOpacity(0.3)),
          ),
          child: const Row(
            children: [
              Icon(Icons.shield_outlined, color: AppTheme.goldLight, size: 30),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Spiritual Fatherhood (የንስሐ አባትነት)',
                      style: TextStyle(fontFamily: 'serif', fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Schedule confidential 1-on-1 confession, spiritual counseling, and communion absolution with campus-assigned clergy.',
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.3),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        const Text(
          'CAMPUS CONFESSOR FATHERS',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.textTertiary, letterSpacing: 1.5),
        ),
        const SizedBox(height: 10),

        ...state.confessorFathers.map((father) {
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: AppTheme.goldAccent.withOpacity(0.15),
                      child: const Icon(Icons.person, color: AppTheme.goldLight, size: 30),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            father.fullName,
                            style: const TextStyle(
                              fontFamily: 'serif',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            father.clericalTitle,
                            style: const TextStyle(fontSize: 12, color: Color(0xFFF5A65E), fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            father.churchName,
                            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.location_on, color: Color(0xFFF5A65E), size: 13),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  father.meetingVenue,
                                  style: const TextStyle(fontSize: 11, color: Color(0xFFF5A65E), fontWeight: FontWeight.w600),
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
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.4),
                ),
                const SizedBox(height: 14),

                // Availability Pills
                const Text('AVAILABLE DAYS:', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.textTertiary, letterSpacing: 1.0)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    ...father.availableDays.map((d) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceElevated,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.borderMuted),
                          ),
                          child: Text(d, style: const TextStyle(fontSize: 10, color: AppTheme.textPrimary)),
                        )),
                  ],
                ),

                const SizedBox(height: 16),
                const Divider(color: AppTheme.borderMuted),
                const SizedBox(height: 10),

                // Action Buttons
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceElevated,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.phone_outlined, color: AppTheme.goldLight, size: 18),
                            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                            padding: const EdgeInsets.all(8),
                            onPressed: () => state.launchCall(father.phoneNumber),
                          ),
                          IconButton(
                            icon: const Icon(Icons.sms_outlined, color: AppTheme.goldLight, size: 18),
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
                        icon: const Icon(Icons.calendar_month, size: 15, color: Colors.black),
                        label: const Text(
                          'Book Appointment',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF5A65E),
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
  Widget _buildAppointmentsAndChecklistTab(FellowshipState state) {
    final myAppts = state.myConfessionAppointments;

    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const Text(
          'MY CONFESSION APPOINTMENTS',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.textTertiary, letterSpacing: 1.5),
        ),
        const SizedBox(height: 10),

        if (myAppts.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.secondaryBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderMuted),
            ),
            child: const Center(
              child: Text(
                'No appointments scheduled yet. Book with a spiritual father above.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
            ),
          )
        else
          ...myAppts.map((appt) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.secondaryBg,
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
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
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
                  Text('Topic: ${appt.topic}', style: const TextStyle(fontSize: 12, color: Color(0xFFF5A65E))),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.schedule, size: 14, color: AppTheme.textSecondary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${appt.scheduledDate.year}-${appt.scheduledDate.month}-${appt.scheduledDate.day} • ${appt.timeSlot}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                        ),
                      ),
                    ],
                  ),
                  if (appt.notes != null && appt.notes!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceElevated,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('Father\'s note: ${appt.notes}', style: const TextStyle(fontSize: 11, color: AppTheme.textPrimary)),
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
                            const SnackBar(content: Text('Appointment cancelled'), backgroundColor: AppTheme.surfaceColor),
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
        const Text(
          'HOLY COMMUNION PREPARATION CHECKLIST (ቅድመ ዝግጅት)',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.textTertiary, letterSpacing: 1.5),
        ),
        const SizedBox(height: 10),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.secondaryBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.borderMuted),
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
                    color: item.isChecked ? Colors.white : AppTheme.textPrimary,
                    decoration: item.isChecked ? TextDecoration.none : null,
                  ),
                ),
                subtitle: Text(
                  item.description,
                  style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
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
  Widget _buildAnonymousQaTab(FellowshipState state) {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        // Ask Anonymous Question Button
        ElevatedButton.icon(
          onPressed: () => _openAskQuestionDialog(context),
          icon: const Icon(Icons.lock_outline, color: Colors.black, size: 18),
          label: const Text('Ask Confidential / Anonymous Question', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFF5A65E),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),

        const SizedBox(height: 20),

        const Text(
          'ANSWERED THEOLOGICAL & MORAL QUESTIONS',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.textTertiary, letterSpacing: 1.5),
        ),
        const SizedBox(height: 10),

        ...state.spiritualQuestions.map((q) {
          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.secondaryBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.borderMuted),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.goldAccent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    q.category,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.goldLight),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Q: ${q.questionText}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white, height: 1.3),
                ),
                const SizedBox(height: 12),
                if (q.isAnswered && q.answerText != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF182333),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.verified, color: Color(0xFF60A5FA), size: 14),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Answered by ${q.answeredBy ?? "Campus Clergy"}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF93C5FD)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          q.answerText!,
                          style: const TextStyle(fontSize: 12, color: Color(0xFFE2E8F0), height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  const Text('Pending answer from Confession Fathers committee...', style: TextStyle(fontSize: 11, color: AppTheme.textTertiary)),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }

  void _openBookingDialog(BuildContext context, ConfessorFatherModel father) {
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
              backgroundColor: AppTheme.surfaceElevated,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text('Book with ${father.fullName}', style: const TextStyle(fontFamily: 'serif', fontSize: 16, color: Color(0xFFF5A65E))),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.goldAccent.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on, color: Color(0xFFF5A65E), size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Meeting Place:\n${father.meetingVenue}',
                              style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600, height: 1.3),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text('Select Topic:', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      value: selectedTopic,
                      dropdownColor: AppTheme.surfaceElevated,
                      items: [
                        'General Confession (ምሥጢረ ንስሐ)',
                        'Communion Preparation (የቁርባን ዝግጅት)',
                        'Spiritual Counseling (የመንፈሳዊ ሕይወት ምክር)',
                        'Campus Moral Challenges (የግቢ ኑሮ ፈተናዎች)',
                      ].map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 12)))).toList(),
                      onChanged: (val) => setDialogState(() => selectedTopic = val!),
                    ),
                    const SizedBox(height: 12),
                    const Text('Select Time Slot:', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      value: selectedSlot,
                      dropdownColor: AppTheme.surfaceElevated,
                      items: father.availableTimeSlots.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 12)))).toList(),
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
                  child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
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
                      const SnackBar(content: Text('Appointment request sent to Confession Father'), backgroundColor: AppTheme.surfaceColor),
                    );
                    setState(() => _activeTab = 1);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF5A65E)),
                  child: const Text('Confirm Booking', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _openAskQuestionDialog(BuildContext context) {
    final qController = TextEditingController();
    String category = 'Campus Life & Morals';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.surfaceElevated,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Ask Confidential Question', style: TextStyle(fontFamily: 'serif', fontSize: 16, color: Color(0xFFF5A65E))),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Your identity and name are never revealed. The question will be reviewed by the fellowship clergy committee.',
                    style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: category,
                    dropdownColor: AppTheme.surfaceElevated,
                    items: ['Campus Life & Morals', 'Fasting & Prayer Rules', 'Theology & Dogma', 'Sacraments & Canon']
                        .map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 12))))
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
                  child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
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
                      const SnackBar(content: Text('Confidential question submitted'), backgroundColor: AppTheme.surfaceColor),
                    );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF5A65E)),
                  child: const Text('Submit', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
