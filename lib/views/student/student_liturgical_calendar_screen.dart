import 'package:flutter/material.dart';
import '../../models/app_models.dart';
import '../../state/fellowship_state.dart';
import '../../theme/app_theme.dart';

class StudentLiturgicalCalendarScreen extends StatefulWidget {
  final FellowshipState state;

  const StudentLiturgicalCalendarScreen({super.key, required this.state});

  @override
  State<StudentLiturgicalCalendarScreen> createState() => _StudentLiturgicalCalendarScreenState();
}

class _StudentLiturgicalCalendarScreenState extends State<StudentLiturgicalCalendarScreen> {
  int _selectedTabIndex = 0; // 0: Daily Readings, 1: Fasting Rules, 2: Synaxarium (ስንክሳር)

  @override
  void initState() {
    super.initState();
    widget.state.addListener(_onStateChange);
  }

  @override
  void dispose() {
    widget.state.removeListener(_onStateChange);
    super.dispose();
  }

  void _onStateChange() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final currentDay = state.currentCalendarDay;

    return Scaffold(
      backgroundColor: AppTheme.primaryBg,
      appBar: AppBar(
        title: const Text('Liturgical Calendar • ባሕረ ሐሳብ'),
        backgroundColor: AppTheme.primaryBg,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: AppTheme.goldLight),
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  backgroundColor: AppTheme.surfaceElevated,
                  title: const Text('Ethiopian Orthodox Calendar', style: TextStyle(fontFamily: 'serif', color: AppTheme.goldLight)),
                  content: const Text(
                    'The Ethiopian Orthodox Tewahedo Church follows the Ge\'ez calendar (ባሕረ ሐሳብ), having 12 months of 30 days plus Pagumēn (ጳጉሜን) of 5 or 6 days. Each day commemorates specific Saints, Angels, and liturgical scriptures.',
                    style: TextStyle(color: AppTheme.textPrimary, fontSize: 13, height: 1.4),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close', style: TextStyle(color: AppTheme.goldLight)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Grand Ethiopian Date & Saint Banner Card
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2C3548), Color(0xFF1B2332), AppTheme.secondaryBg],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.goldAccent.withOpacity(0.4), width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.goldAccent.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.goldAccent.withOpacity(0.5)),
                        ),
                        child: Text(
                          currentDay.geezDateString,
                          style: const TextStyle(
                            fontFamily: 'serif',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFF5A65E),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: currentDay.isFasting ? const Color(0xFFEF4444).withOpacity(0.2) : const Color(0xFF10B981).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: currentDay.isFasting ? const Color(0xFFEF4444).withOpacity(0.5) : const Color(0xFF10B981).withOpacity(0.5),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              currentDay.isFasting ? Icons.restaurant_menu : Icons.sentiment_satisfied_alt,
                              size: 14,
                              color: currentDay.isFasting ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              currentDay.isFasting ? 'Fasting Day' : 'Non-Fasting',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: currentDay.isFasting ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    currentDay.saintOfTodayGeEz,
                    style: const TextStyle(
                      fontFamily: 'serif',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currentDay.saintOfToday,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBg.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.wb_twilight, color: AppTheme.goldLight, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            currentDay.fastName,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        if (currentDay.isFasting)
                          Text(
                            'Until ${currentDay.fastingUntilHour}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.goldLight,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 2. Day Selector Carousel
            const Text(
              'SELECT DAY • ዕለታት',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppTheme.textTertiary,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 10),

            SizedBox(
              height: 70,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: state.calendarWeek.length,
                itemBuilder: (context, index) {
                  final day = state.calendarWeek[index];
                  final isSelected = day.geezDateString == currentDay.geezDateString;

                  return GestureDetector(
                    onTap: () => state.selectCalendarDay(day),
                    child: Container(
                      width: 110,
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF2B3648) : AppTheme.secondaryBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? AppTheme.goldAccent : AppTheme.borderMuted,
                          width: isSelected ? 1.5 : 1.0,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            day.geezDateString,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? const Color(0xFFF5A65E) : AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            day.isFasting ? 'Fasting' : 'Free',
                            style: TextStyle(
                              fontSize: 10,
                              color: day.isFasting ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 22),

            // 3. Segmented Navigation Tabs (Readings / Fasting Rules / Synaxarium)
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppTheme.secondaryBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderMuted),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildTabPill(
                      title: 'Scriptures (ምንባባት)',
                      icon: Icons.auto_stories,
                      index: 0,
                    ),
                  ),
                  Expanded(
                    child: _buildTabPill(
                      title: 'Rules (ሥርዓተ ጾም)',
                      icon: Icons.rule,
                      index: 1,
                    ),
                  ),
                  Expanded(
                    child: _buildTabPill(
                      title: 'Synaxarium (ስንክሳር)',
                      icon: Icons.history_edu,
                      index: 2,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // 4. Tab Views
            if (_selectedTabIndex == 0) _buildScripturesTab(currentDay.scriptures),
            if (_selectedTabIndex == 1) _buildFastingRulesTab(currentDay),
            if (_selectedTabIndex == 2) _buildSynaxariumTab(currentDay),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildTabPill({required String title, required IconData icon, required int index}) {
    final isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTabIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.surfaceElevated : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? Border.all(color: AppTheme.goldAccent.withOpacity(0.4)) : null,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? AppTheme.goldLight : AppTheme.textSecondary,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
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

  Widget _buildScripturesTab(DailyScriptureModel sc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Daily Reflection Quote Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E2838),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.goldAccent.withOpacity(0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.format_quote, color: AppTheme.goldLight, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  sc.reflection,
                  style: const TextStyle(
                    fontFamily: 'serif',
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: Color(0xFFF3F4F6),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        _buildScriptureTile('Epistle of St. Paul (መልእክተ ጳውሎስ)', sc.epistle, Icons.mail_outline),
        _buildScriptureTile('Catholic Epistle (መልእክተ ሐዋርያት)', sc.catholicEpistle, Icons.menu_book),
        _buildScriptureTile('Acts of the Apostles (ግብረ ሐዋርያት)', sc.acts, Icons.history),
        _buildScriptureTile('Daily Psalm (ምስባከ ዳዊት)', sc.psalm, Icons.music_note),
        _buildScriptureTile('Holy Gospel (ወንጌል ቅዱስ)', sc.gospel, Icons.local_fire_department, isHighlight: true),
      ],
    );
  }

  Widget _buildScriptureTile(String label, String reading, IconData icon, {bool isHighlight = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isHighlight ? const Color(0xFF252F42) : AppTheme.secondaryBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isHighlight ? AppTheme.goldAccent.withOpacity(0.6) : AppTheme.borderMuted),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isHighlight ? AppTheme.goldAccent.withOpacity(0.2) : AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: isHighlight ? AppTheme.goldLight : AppTheme.textSecondary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: isHighlight ? AppTheme.goldLight : AppTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  reading,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isHighlight ? Colors.white : AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFastingRulesTab(EthiopianCalendarDay day) {
    return Container(
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
              Icon(
                day.isFasting ? Icons.hourglass_top : Icons.done_all,
                color: day.isFasting ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                size: 22,
              ),
              const SizedBox(width: 10),
              Text(
                day.fastName,
                style: const TextStyle(
                  fontFamily: 'serif',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            day.fastRules,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(color: AppTheme.borderMuted),
          const SizedBox(height: 12),
          _buildRuleRow('Fasting Duration', day.isFasting ? 'Until 3:00 PM (9:00 LT)' : 'None'),
          _buildRuleRow('Dietary Observance', day.isFasting ? 'Vegan (No meat, dairy, eggs)' : 'Regular food permitted'),
          _buildRuleRow('Fish Permitted?', day.isFishAllowed ? 'Yes (በዓለ ሃምሳ / ገሃድ)' : 'No (የተከለከለ)'),
        ],
      ),
    );
  }

  Widget _buildRuleRow(String key, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(key, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildSynaxariumTab(EthiopianCalendarDay day) {
    return Container(
      padding: const EdgeInsets.all(20),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.goldAccent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.history_edu, color: AppTheme.goldLight, size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Synaxarium • መጽሐፈ ስንክሳር',
                      style: TextStyle(
                        fontFamily: 'serif',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Commemoration of the Saints of Today',
                      style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            day.scriptures.synaxariumExcerpt,
            style: const TextStyle(
              fontFamily: 'serif',
              fontSize: 14,
              color: AppTheme.textPrimary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
