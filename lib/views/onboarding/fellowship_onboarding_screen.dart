import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/app_models.dart';
import '../../state/fellowship_state.dart';
import '../../theme/app_theme.dart';

class FellowshipOnboardingScreen extends StatefulWidget {
  final FellowshipState state;
  final VoidCallback onFinish;
  final VoidCallback onSignIn;

  const FellowshipOnboardingScreen({
    super.key,
    required this.state,
    required this.onFinish,
    required this.onSignIn,
  });

  @override
  State<FellowshipOnboardingScreen> createState() => _FellowshipOnboardingScreenState();
}

class _FellowshipOnboardingScreenState extends State<FellowshipOnboardingScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isInSetupWizard = false;
  int _wizardStep = 0; // 0: Focus, 1: Fellowship Alerts, 2: Sacred Look

  // Audio preview animation state
  bool _isPlayingAudio = false;
  late AnimationController _waveController;

  // Wizard preferences
  String _selectedMinistry = 'dept-choir';
  bool _dailyReminderEnabled = true;
  AppThemePalette _selectedPalette = AppThemePalette.midnightFellowship;
  double _fontSizeScale = 1.0; // 0.9, 1.0, 1.15

  @override
  void initState() {
    super.initState();
    _selectedPalette = widget.state.currentThemePalette;
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  void _nextPage() {
    HapticFeedback.lightImpact();
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    } else {
      setState(() {
        _isInSetupWizard = true;
        _wizardStep = 0;
      });
    }
  }

  void _nextWizardStep() {
    HapticFeedback.lightImpact();
    if (_wizardStep < 2) {
      setState(() => _wizardStep++);
    } else {
      _completeOnboarding();
    }
  }

  Future<void> _completeOnboarding() async {
    HapticFeedback.mediumImpact();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('preferred_ministry_focus_v1', _selectedMinistry);
      await prefs.setBool('liturgy_reminder_enabled_v1', _dailyReminderEnabled);
      await prefs.setBool('has_completed_onboarding_tour_v1', true);
    } catch (_) {}
    widget.state.setThemePalette(_selectedPalette);
    widget.onFinish();
  }

  @override
  Widget build(BuildContext context) {
    // Deep radial emerald-and-gold gradient background
    const bgGradient = RadialGradient(
      center: Alignment(0, -0.2),
      radius: 1.2,
      colors: [
        Color(0xFF0F3238), // Luminous emerald glow
        Color(0xFF081B1F), // Deep teal
        Color(0xFF030D10), // Midnight abyss
      ],
      stops: [0.0, 0.45, 1.0],
    );

    return Scaffold(
      backgroundColor: const Color(0xFF030D10),
      body: Container(
        decoration: const BoxDecoration(gradient: bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Top Bar with Cross Branding & Skip
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFFE5A93C), width: 1.2),
                              color: const Color(0xFFE5A93C).withOpacity(0.12),
                            ),
                            child: const Center(
                              child: Icon(Icons.church_rounded, size: 16, color: Color(0xFFE5A93C)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'WCU Gibi Gubae • የዋቸሞ ዩኒቨርሲቲ ግቢ ጉባኤ',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'serif',
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFE5A93C),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: _completeOnboarding,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white70,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        _isInSetupWizard ? 'Skip setup' : 'Skip',
                        style: const TextStyle(fontSize: 12, color: Colors.white70),
                      ),
                    ),
                  ],
                ),
              ),

              // Main Body Content (Onboarding Tour OR Setup Wizard)
              Expanded(
                child: _isInSetupWizard
                    ? _buildSetupWizard()
                    : PageView(
                        controller: _pageController,
                        onPageChanged: (idx) => setState(() => _currentPage = idx),
                        children: [
                          _buildSlide1SpiritualFamily(),
                          _buildSlide2MinistriesAndFathers(),
                          _buildSlide3LiturgyAndPilgrimage(),
                          _buildSlide4MutualAidAndThemes(),
                        ],
                      ),
              ),

              // Bottom Control Strip (Pagination + Continue Button)
              _buildBottomControls(),
            ],
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // SLIDE 1: SPIRITUAL FAMILY & MENTORSHIP (የመንፈስ ቤተሰብና አካዳሚክ ማማከር)
  // --------------------------------------------------------------------------
  Widget _buildSlide1SpiritualFamily() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  const Spacer(),

                  // Central Illuminated Graphic Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A2328).withOpacity(0.85),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: const Color(0xFFE5A93C).withOpacity(0.35), width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE5A93C).withOpacity(0.12),
                          blurRadius: 30,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Glowing Medallion Icon
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: const LinearGradient(
                              colors: [Color(0xFFE5A93C), Color(0xFF8E6317)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFE5A93C).withOpacity(0.3),
                                blurRadius: 16,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(Icons.family_restroom_rounded, color: Color(0xFF030D10), size: 28),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Scripture citation
                        const Text(
                          '— መዝሙር ፻፴፪፥፩ • Psalm 133:1',
                          style: TextStyle(
                            fontFamily: 'serif',
                            fontSize: 13,
                            color: Color(0xFFE5A93C),
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Scripture Quote with Luminous Highlight Chips
                        RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: const TextStyle(
                              fontFamily: 'serif',
                              fontSize: 15,
                              height: 1.6,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                            children: [
                              WidgetSpan(
                                alignment: PlaceholderAlignment.middle,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE5A93C).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: const Color(0xFFE5A93C), width: 1),
                                  ),
                                  child: const Text(
                                    'ወንድሞች',
                                    style: TextStyle(
                                      fontFamily: 'serif',
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFF3C766),
                                    ),
                                  ),
                                ),
                              ),
                              const TextSpan(text: ' '),
                              WidgetSpan(
                                alignment: PlaceholderAlignment.middle,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: const Color(0xFF10B981), width: 1),
                                  ),
                                  child: const Text(
                                    'በኅብረት',
                                    style: TextStyle(
                                      fontFamily: 'serif',
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF34D399),
                                    ),
                                  ),
                                ),
                              ),
                              const TextSpan(text: ' ቢቀመጡ መልካም ነው፥ እንዴትም ያማረ ነው!'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          '"Behold, how good and pleasant it is for brethren to dwell together in unity!"',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 11, color: Colors.white60, fontStyle: FontStyle.italic),
                        ),
                        const SizedBox(height: 16),

                        // Dark inset preview strip (#05171B)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF05171B),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white.withOpacity(0.08)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.shield_outlined, color: Color(0xFFE5A93C), size: 14),
                                  const SizedBox(width: 6),
                                  const Expanded(
                                    child: Text(
                                      'Family of St. George • የቅዱስ ጊዮርጊስ ቤተሰብ',
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  _buildFeaturePill('ቅዱስ ጊዮርጊስ (St. George)'),
                                  _buildFeaturePill('ቅድስት አርሴማ (St. Arsema)'),
                                  _buildFeaturePill('Spiritual Parents (የመንፈስ አባትና እናት)'),
                                  _buildFeaturePill('Senior Academic Mentors (አካዳሚክ ማማከር)'),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Text Heading Block
                  const Text(
                    'SPIRITUAL FAMILY & MENTORSHIP',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFE5A93C),
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Your spiritual home at\nWachemo University.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Get matched into a Saint-named Spiritual Family with campus parents,\nconnect with siblings on Telegram, and find senior academic mentors.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // --------------------------------------------------------------------------
  // SLIDE 2: 10 EOTC MINISTRIES, PATRISTIC FATHERS & CONFESSOR (፲ የአገልግሎት ክፍሎችና የንስሐ አባት)
  // --------------------------------------------------------------------------
  Widget _buildSlide2MinistriesAndFathers() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  const Spacer(),

                  // Patristics & Ministries Card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A2328).withOpacity(0.85),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: const Color(0xFFE5A93C).withOpacity(0.35), width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0F3238).withOpacity(0.4),
                          blurRadius: 25,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Verse citation
                        const Text(
                          '1 PETER 4:10 • ፩ ጴጥሮስ ፬፥፲',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFE5A93C),
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              fontFamily: 'serif',
                              fontSize: 15,
                              color: Colors.white,
                              height: 1.5,
                            ),
                            children: [
                              const TextSpan(text: 'እያንዳንዱ እንደ ተቀበለው የ'),
                              WidgetSpan(
                                alignment: PlaceholderAlignment.middle,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE5A93C).withOpacity(0.25),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: const Color(0xFFE5A93C), width: 1.5),
                                  ),
                                  child: const Text(
                                    'ጸጋ',
                                    style: TextStyle(
                                      fontFamily: 'serif',
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFF3C766),
                                    ),
                                  ),
                                ),
                              ),
                              const TextSpan(text: ' ስጦታ መጠን እርስ በርሳችሁ አገልግሉ።'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          '"As each has received a gift, use it to serve one another."',
                          style: TextStyle(fontSize: 11, color: Colors.white60, fontStyle: FontStyle.italic),
                        ),
                        const SizedBox(height: 12),

                        // Ministry chips row
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            _buildDepartmentChip('ትምህርት (Education)'),
                            _buildDepartmentChip('መዝሙር (Choir)'),
                            _buildDepartmentChip('አባላት እንክብካቤ (Care)'),
                            _buildDepartmentChip('ስነ ጥበባት (Arts)'),
                            _buildDepartmentChip('በጎ አድራጎት (Charity)'),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Bottom dark inset card (#05171B)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF05171B),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white.withOpacity(0.08)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'CONFESSOR FATHERS & PATRISTICS • የንስሐ አባትና ነገረ አበው',
                                style: TextStyle(fontSize: 10, color: Color(0xFFE5A93C), fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Expanded(
                                    child: Text(
                                      '1-on-1 Confession & Spiritual Q&A',
                                      style: TextStyle(fontFamily: 'serif', fontSize: 13, color: Colors.white, fontWeight: FontWeight.bold),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _buildFatherBadge('ዮ', 'St. John Chrysostom • ቅዱስ ዮሐንስ አፈወርቅ'),
                                      const SizedBox(width: 4),
                                      _buildFatherBadge('ቄ', 'St. Cyril • ቅዱስ ቄርሎስ'),
                                      const SizedBox(width: 4),
                                      _buildFatherBadge('ተ', 'Abune Teklehaimanot • አቡነ ተክለ ሃይማኖት'),
                                      const SizedBox(width: 4),
                                      const Text('Fathers', style: TextStyle(fontSize: 10, color: Colors.white70)),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                '"No one heals a soul like a loving spiritual father." — Book private confession slots & ask questions anonymously.',
                                style: TextStyle(fontSize: 11, color: Colors.white60, height: 1.3),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  const Text(
                    'SERVE & GROW',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFE5A93C),
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Serve in 10 ministries &\nwalk with the Fathers.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Apply to serve in 10 EOTC fellowship departments, study patristic roadmaps,\nand book confidential appointments with campus Confessor Fathers.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeaturePill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFE5A93C).withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE5A93C).withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 9.5, color: Color(0xFFF3C766), fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildDepartmentChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 10, color: Color(0xFF34D399), fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildFatherBadge(String initial, String tooltip) {
    return Tooltip(
      message: tooltip,
      child: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFFE5A93C).withOpacity(0.2),
          border: Border.all(color: const Color(0xFFE5A93C), width: 1),
        ),
        child: Center(
          child: Text(
            initial,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFF3C766)),
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // SLIDE 3: HOLY LITURGY, ST. YARED MEZMUR, LIVE QR ATTENDANCE & PILGRIMAGE (ቅዳሴ፣ ቅዱስ ያሬድ፣ QR መገኘትና የንግሥ ጉዞ)
  // --------------------------------------------------------------------------
  Widget _buildSlide3LiturgyAndPilgrimage() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  const Spacer(),

                  // Daily Lectionary & Audio Card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A2328).withOpacity(0.85),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: const Color(0xFFE5A93C).withOpacity(0.35), width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0F3238).withOpacity(0.4),
                          blurRadius: 25,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top Strip
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Expanded(
                              child: Row(
                                children: [
                                  Icon(Icons.church_outlined, size: 14, color: Color(0xFFE5A93C)),
                                  SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'የዕለቱ ስንክሳር፣ ቅዳሴና የንግሥ ጉዞ',
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFE5A93C)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text('ጥቅምት ፲፬ • አቡነ አረጋዊ', style: TextStyle(fontSize: 9.5, color: Color(0xFF34D399), fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Psalm 122:1
                        const Text(
                          '“ወደ እግዚአብሔር ቤት እንሂድ ባሉኝ ጊዜ ደስ አለኝ።” — መዝሙር ፻፳፩፥፩ (Psalm 122:1)',
                          style: TextStyle(fontFamily: 'serif', fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600, height: 1.3),
                        ),
                        const SizedBox(height: 12),

                        // Ge'ez Week Days Ribbon
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildDayChip('ሰ', '12', false),
                            _buildDayChip('ማ', '13', false),
                            _buildDayChip('ረ', '14', true), // Active selected
                            _buildDayChip('ሐ', '15', false),
                            _buildDayChip('ዓ', '16', false),
                            _buildDayChip('ቀ', '17', false),
                            _buildDayChip('እ', '18', false),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Feature Pills Row
                        const Row(
                          children: [
                            _AttendancePill(label: '⚡ 30s Live QR/PIN Attendance'),
                            SizedBox(width: 8),
                            _AttendancePill(label: '🚌 Monastery Pilgrimage Pass'),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Audio Hymn / St. Yared Mezmur Player Preview
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF05171B),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white.withOpacity(0.08)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Expanded(
                                    child: Text(
                                      'ቅዱስ ያሬድ (St. Yared) • የሰንበት መዝሙርና ዲጂታል ላይብረሪ',
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontFamily: 'serif', fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _isPlayingAudio ? '0:42 / 3:15' : 'Preview',
                                    style: const TextStyle(fontSize: 10, color: Colors.white60),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Tap play to preview • Wudase Maryam (ቅዱስ ኤፍሬም), Zema & Patristic PDFs',
                                style: TextStyle(fontSize: 9.5, color: Colors.white60),
                              ),
                              const SizedBox(height: 10),

                              // Player Row with Play Button + Animated Waveform
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      HapticFeedback.lightImpact();
                                      setState(() {
                                        _isPlayingAudio = !_isPlayingAudio;
                                        if (_isPlayingAudio) {
                                          _waveController.repeat(reverse: true);
                                        } else {
                                          _waveController.stop();
                                        }
                                      });
                                    },
                                    child: Container(
                                      width: 36,
                                      height: 36,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Color(0xFFE5A93C),
                                      ),
                                      child: Icon(
                                        _isPlayingAudio ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                        color: const Color(0xFF030D10),
                                        size: 22,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: AnimatedBuilder(
                                      animation: _waveController,
                                      builder: (context, _) {
                                        return Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: List.generate(24, (i) {
                                            final progress = _isPlayingAudio ? _waveController.value : 0.2;
                                            final barHeight = 4.0 + (math.sin(i * 0.5 + progress * 6.28).abs() * 18.0);
                                            final isPlayed = i < 10;

                                            return Container(
                                              width: 3,
                                              height: barHeight,
                                              decoration: BoxDecoration(
                                                color: isPlayed ? const Color(0xFFE5A93C) : Colors.white24,
                                                borderRadius: BorderRadius.circular(2),
                                              ),
                                            );
                                          }),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  const Text(
                    'CAMPUS FELLOWSHIP LIFE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFE5A93C),
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Liturgy, Live QR check-in\n& monastery pilgrimages.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Commemorate daily Saints in the Synaxarium, check in with 30-second QR codes,\nbook monastery pilgrimage bus seats, and stream St. Yared Mezmurs.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDayChip(String weekday, String dayNumber, bool isSelected) {
    return Column(
      children: [
        Text(
          weekday,
          style: TextStyle(
            fontSize: 11,
            color: isSelected ? const Color(0xFFE5A93C) : Colors.white54,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFE5A93C) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: isSelected ? null : Border.all(color: Colors.white12),
          ),
          child: Center(
            child: Text(
              dayNumber,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelected ? const Color(0xFF030D10) : Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // SLIDE 4: MUTUAL AID, FAITH TRIVIA & SACRED THEMES (መረዳጃ፣ የዕውቀት ውድድርና ገጽታ)
  // --------------------------------------------------------------------------
  Widget _buildSlide4MutualAidAndThemes() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  const Spacer(),

                  // Fanned 3D Perspective Cards Named After Saints
                  SizedBox(
                    height: 180,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Card 1: St. Ephrem - Parchment & Incense (Left Tilted)
                        Transform(
                          alignment: Alignment.bottomCenter,
                          transform: Matrix4.identity()
                            ..translate(-55.0, 10.0, 0.0)
                            ..rotateZ(-0.14),
                          child: _buildStackCard(
                            title: 'ቅዱስ ኤፍሬም',
                            sub: 'Parchment & Incense',
                            bgColor: const Color(0xFFF9F5EC),
                            textColor: const Color(0xFF2C2419),
                            accentColor: const Color(0xFFB45309),
                          ),
                        ),

                        // Card 3: Abune Teklehaimanot - Axumite Emerald (Right Tilted)
                        Transform(
                          alignment: Alignment.bottomCenter,
                          transform: Matrix4.identity()
                            ..translate(55.0, 10.0, 0.0)
                            ..rotateZ(0.14),
                          child: _buildStackCard(
                            title: 'አቡነ ተክለ ሃይማኖት',
                            sub: 'Axumite Emerald',
                            bgColor: const Color(0xFF042018),
                            textColor: Colors.white,
                            accentColor: const Color(0xFF10B981),
                          ),
                        ),

                        // Card 2: St. Yared - Midnight Gold (Center Elevated)
                        Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()..translate(0.0, -10.0, 0.0),
                          child: _buildStackCard(
                            title: 'ቅዱስ ያሬድ',
                            sub: 'Midnight Gold',
                            bgColor: const Color(0xFF0A1828),
                            textColor: Colors.white,
                            accentColor: const Color(0xFFE5A93C),
                            isCenter: true,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Galatians 6:2 Mutual Aid Scripture
                  const Text(
                    '“እርስ በርሳችሁ ሸክማችሁን ተሸካከሙ” — ገላትያ ፮፥፪ (Galatians 6:2)',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFE5A93C),
                    ),
                  ),
                  const SizedBox(height: 8),

                  const Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    children: [
                      Text('MUTUAL AID', style: TextStyle(fontSize: 10, letterSpacing: 1.5, color: Colors.white70, fontWeight: FontWeight.bold)),
                      Text('•', style: TextStyle(color: Color(0xFFE5A93C))),
                      Text('FAITH TRIVIA', style: TextStyle(fontSize: 10, letterSpacing: 1.5, color: Colors.white70, fontWeight: FontWeight.bold)),
                      Text('•', style: TextStyle(color: Color(0xFFE5A93C))),
                      Text('SACRED THEMES', style: TextStyle(fontSize: 10, letterSpacing: 1.5, color: Colors.white70, fontWeight: FontWeight.bold)),
                    ],
                  ),

                  const Spacer(),

                  const Text(
                    'MADE FOR WCU FELLOWS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFE5A93C),
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Mutual aid, faith trivia &\nyour sacred theme.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Support fellow students through confidential emergency aid, compete in\nweekly family faith trivia, and customize your fellowship experience.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStackCard({
    required String title,
    required String sub,
    required Color bgColor,
    required Color textColor,
    required Color accentColor,
    bool isCenter = false,
  }) {
    return Container(
      width: 140,
      height: 160,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withOpacity(isCenter ? 0.8 : 0.4), width: isCenter ? 2 : 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: isCenter ? 20 : 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(Icons.auto_stories, color: accentColor, size: 18),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(shape: BoxShape.circle, color: accentColor),
              ),
            ],
          ),
          const Spacer(),
          Text(
            title,
            style: TextStyle(
              fontFamily: 'serif',
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: TextStyle(fontSize: 10, color: textColor.withOpacity(0.7)),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // INTERACTIVE 3-STEP SETUP WIZARD
  // --------------------------------------------------------------------------
  Widget _buildSetupWizard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step Indicator Bar
          Row(
            children: [
              _buildStepIndicator(0, 'Focus'),
              _buildStepDivider(),
              _buildStepIndicator(1, 'Alerts'),
              _buildStepDivider(),
              _buildStepIndicator(2, 'Look'),
            ],
          ),
          const SizedBox(height: 20),

          if (_wizardStep == 0) _buildWizardStep1Focus(),
          if (_wizardStep == 1) _buildWizardStep2Alerts(),
          if (_wizardStep == 2) _buildWizardStep3Look(),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int stepIndex, String title) {
    final isActive = _wizardStep == stepIndex;
    final isDone = _wizardStep > stepIndex;

    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? const Color(0xFFE5A93C) : (isDone ? const Color(0xFF10B981) : Colors.white12),
          ),
          child: Center(
            child: isDone
                ? const Icon(Icons.check, size: 13, color: Colors.black)
                : Text(
                    '${stepIndex + 1}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isActive ? Colors.black : Colors.white70,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? const Color(0xFFE5A93C) : Colors.white60,
          ),
        ),
      ],
    );
  }

  Widget _buildStepDivider() {
    return Expanded(
      child: Container(
        height: 1,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        color: Colors.white12,
      ),
    );
  }

  // WIZARD STEP 1: CHOOSE FOCUS (YOUR FOCUS / የአገልግሎት ዘርፍ)
  Widget _buildWizardStep1Focus() {
    final ministries = [
      {'id': 'dept-choir', 'title': 'Choir & Mezmur (ዝማሬ)', 'sub': 'Liturgical hymns & audio practice', 'icon': Icons.music_note},
      {'id': 'dept-education', 'title': 'Education & Apostolic (ትምህርት)', 'sub': 'Catechism, dogma & patristics', 'icon': Icons.school_outlined},
      {'id': 'dept-pilgrimage', 'title': 'Pilgrimage & Trips (መንፈሳዊ ጉዞ)', 'sub': 'Monastery passes & holy sites', 'icon': Icons.directions_bus_outlined},
      {'id': 'dept-charity', 'title': 'Charity & Mutual Aid (መረዳጃ)', 'sub': 'Student welfare & medical aid', 'icon': Icons.volunteer_activism_outlined},
      {'id': 'dept-mentorship', 'title': 'Academic Mentorship (ማማከር)', 'sub': 'Senior peer tutoring & guidance', 'icon': Icons.people_outline},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'YOUR FOCUS',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFFE5A93C), letterSpacing: 2.0),
        ),
        const SizedBox(height: 6),
        const Text(
          'Choose your first fellowship path.',
          style: TextStyle(fontFamily: 'serif', fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 4),
        const Text(
          'Pick where you wish to serve or engage. You can explore all 10 departments at any time.',
          style: TextStyle(fontSize: 12, color: Colors.white70),
        ),
        const SizedBox(height: 18),

        ...ministries.map((m) {
          final isSelected = _selectedMinistry == m['id'];

          return GestureDetector(
            onTap: () => setState(() => _selectedMinistry = m['id'] as String),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFE5A93C).withOpacity(0.12) : const Color(0xFF0A2328).withOpacity(0.6),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? const Color(0xFFE5A93C) : Colors.white12,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(m['icon'] as IconData, color: isSelected ? const Color(0xFFE5A93C) : Colors.white60, size: 22),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          m['title'] as String,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? const Color(0xFFF3C766) : Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          m['sub'] as String,
                          style: const TextStyle(fontSize: 11, color: Colors.white60),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    const Icon(Icons.check_circle_rounded, color: Color(0xFFE5A93C), size: 18),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  // WIZARD STEP 2: FELLOWSHIP ALERTS (የቅዳሴና የመርሐ ግብር ማስታወሻ)
  Widget _buildWizardStep2Alerts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'FELLOWSHIP ALERTS',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFFE5A93C), letterSpacing: 2.0),
        ),
        const SizedBox(height: 6),
        const Text(
          'Walk in the rhythm of the Church.',
          style: TextStyle(fontFamily: 'serif', fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 4),
        const Text(
          'Receive reminders for Sunday Holy Liturgy, daily Saints commemoration (ስንክሳር), and live course attendance.',
          style: TextStyle(fontSize: 12, color: Colors.white70),
        ),
        const SizedBox(height: 18),

        // Lectionary Options
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF0A2328).withOpacity(0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5A93C), width: 1.5),
          ),
          child: const Row(
            children: [
              Icon(Icons.church, color: Color(0xFFE5A93C), size: 22),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ኦርቶዶክስ ተዋሕዶ (Orthodox Tewahedo Lectionary)',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFF3C766)),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Daily Synaxarium (ስንክሳር), Wudase Maryam, Sunday Liturgy & Fasting rules',
                      style: TextStyle(fontSize: 11, color: Colors.white60),
                    ),
                  ],
                ),
              ),
              Icon(Icons.check_circle_rounded, color: Color(0xFFE5A93C), size: 18),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Liturgy & Fellowship Reminders Switch Card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF0A2328).withOpacity(0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white12),
          ),
          child: Row(
            children: [
              const Icon(Icons.notifications_active_outlined, color: Color(0xFFE5A93C), size: 22),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Liturgy & Fellowship Reminders',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Notify me before Sunday Holy Liturgy and scheduled fellowship programs.',
                      style: TextStyle(fontSize: 11, color: Colors.white60),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _dailyReminderEnabled,
                activeColor: const Color(0xFFE5A93C),
                onChanged: (val) => setState(() => _dailyReminderEnabled = val),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // WIZARD STEP 3: SACRED LOOK (YOUR SACRED LOOK / የመተግበሪያው ገጽታ)
  Widget _buildWizardStep3Look() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'YOUR SACRED LOOK',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFFE5A93C), letterSpacing: 2.0),
        ),
        const SizedBox(height: 6),
        const Text(
          'Personalize your fellowship app.',
          style: TextStyle(fontFamily: 'serif', fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 4),
        const Text(
          'Pick a sacred color palette and text size. Preview how your scripture and fellowship cards will look.',
          style: TextStyle(fontSize: 12, color: Colors.white70),
        ),
        const SizedBox(height: 18),

        // LIVE SCRIPTURE PREVIEW BOX
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _selectedPalette == AppThemePalette.parchmentIncense
                ? const Color(0xFFF9F5EC)
                : (_selectedPalette == AppThemePalette.axumiteEmerald ? const Color(0xFF031E18) : const Color(0xFF071424)),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _selectedPalette == AppThemePalette.parchmentIncense
                  ? const Color(0xFFB45309)
                  : (_selectedPalette == AppThemePalette.axumiteEmerald ? const Color(0xFF10B981) : const Color(0xFFE5A93C)),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 16,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'ዮሐንስ ፩:፲፬ • John 1:14 — ቅዱስ ዮሐንስ ወንጌላዊ',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _selectedPalette == AppThemePalette.parchmentIncense ? const Color(0xFFB45309) : const Color(0xFFE5A93C),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _selectedPalette.displayName,
                    style: TextStyle(
                      fontSize: 10,
                      color: _selectedPalette == AppThemePalette.parchmentIncense ? Colors.black54 : Colors.white60,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'ቃልም ሥጋ ሆነ፤ በእኛም አደረ፥ ጸጋንና እውነትንም ተሞልቶ የአባቱ አንድያ ልጅ እንዳለው ክብር የሆነው ክብሩን አየን።',
                style: TextStyle(
                  fontFamily: 'serif',
                  fontSize: 15 * _fontSizeScale,
                  height: 1.6,
                  color: _selectedPalette == AppThemePalette.parchmentIncense ? const Color(0xFF2C2419) : Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (_selectedPalette == AppThemePalette.parchmentIncense
                          ? const Color(0xFFB45309)
                          : (_selectedPalette == AppThemePalette.axumiteEmerald ? const Color(0xFF10B981) : const Color(0xFFE5A93C)))
                      .withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'WCU Gibi Gubae • Family, 10 Ministries & Pilgrimage',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: _selectedPalette == AppThemePalette.parchmentIncense
                        ? const Color(0xFFB45309)
                        : (_selectedPalette == AppThemePalette.axumiteEmerald ? const Color(0xFF34D399) : const Color(0xFFF3C766)),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // Palette Selector Swatches
        const Text('SACRED PALETTE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white70, letterSpacing: 1.2)),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildPaletteTile(AppThemePalette.midnightFellowship, 'Midnight Gold', const Color(0xFF071424), const Color(0xFFE5A93C)),
            _buildPaletteTile(AppThemePalette.axumiteEmerald, 'Axumite Emerald', const Color(0xFF031E18), const Color(0xFF10B981)),
            _buildPaletteTile(AppThemePalette.parchmentIncense, 'Parchment & Incense', const Color(0xFFF9F5EC), const Color(0xFFB45309)),
          ],
        ),

        const SizedBox(height: 18),

        // Font Size Controls
        const Text('FONT SIZE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white70, letterSpacing: 1.2)),
        const SizedBox(height: 10),
        Row(
          children: [
            _buildSizeButton('Regular', 1.0),
            const SizedBox(width: 10),
            _buildSizeButton('Comfortable', 1.15),
            const SizedBox(width: 10),
            _buildSizeButton('Large', 1.3),
          ],
        ),
      ],
    );
  }

  Widget _buildPaletteTile(AppThemePalette palette, String title, Color bg, Color accent) {
    final isSelected = _selectedPalette == palette;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedPalette = palette);
      },
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: bg,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? accent : Colors.white24,
                width: isSelected ? 3 : 1,
              ),
              boxShadow: [
                if (isSelected)
                  BoxShadow(
                    color: accent.withOpacity(0.4),
                    blurRadius: 10,
                  ),
              ],
            ),
            child: isSelected ? Center(child: Icon(Icons.check, size: 18, color: accent)) : null,
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: isSelected ? accent : Colors.white60,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSizeButton(String label, double scale) {
    final isSelected = (_fontSizeScale - scale).abs() < 0.05;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _fontSizeScale = scale);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFE5A93C).withOpacity(0.2) : const Color(0xFF0A2328).withOpacity(0.6),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isSelected ? const Color(0xFFE5A93C) : Colors.white12),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? const Color(0xFFF3C766) : Colors.white70,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // BOTTOM CONTROLS (PAGINATION DOTS + ACTION BUTTON)
  // --------------------------------------------------------------------------
  Widget _buildBottomControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      child: Column(
        children: [
          // Pagination Dots (Only shown on Onboarding Tour, not in Wizard)
          if (!_isInSetupWizard)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                final isSelected = _currentPage == index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: isSelected ? 22 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFE5A93C) : Colors.white24,
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),

          const SizedBox(height: 14),

          // Primary Action Button (Continue > / Set up my Fellowship > / Enter Fellowship >)
          ElevatedButton(
            onPressed: _isInSetupWizard ? _nextWizardStep : _nextPage,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE5A93C),
              foregroundColor: const Color(0xFF030D10),
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
              elevation: 4,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _isInSetupWizard
                      ? (_wizardStep == 2 ? 'Enter Fellowship • ወደ ግቢ ጉባኤ ግባ' : 'Continue')
                      : (_currentPage == 3 ? 'Set up my Fellowship' : 'Continue'),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_rounded, size: 18),
              ],
            ),
          ),

          // Sign In Link (for returning students)
          const SizedBox(height: 8),
          TextButton(
            onPressed: widget.onSignIn,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Already a member? Sign in / አባል ኖት? ግቡ',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFFE5A93C),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AttendancePill extends StatelessWidget {
  final String label;

  const _AttendancePill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF10B981).withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF34D399)),
        ),
      ),
    );
  }
}
