import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  int _wizardStep = 0; // 0: Focus, 1: Daily Reading, 2: Sacred Look

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

  void _completeOnboarding() {
    HapticFeedback.mediumImpact();
    widget.state.setThemePalette(_selectedPalette);
    widget.onFinish();
  }

  @override
  Widget build(BuildContext context) {
    // Elegant deep sacred background inspired by the reference video
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
                              'መጽሐፈ ቅዱስ • ግቢ ጉባኤ',
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
                          _buildSlide1LightForThePath(),
                          _buildSlide2StudyDeeper(),
                          _buildSlide3DailyRhythm(),
                          _buildSlide4MakeItYours(),
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
  // SLIDE 1: LIGHT FOR THE PATH (መብራትና ብርሃን)
  // --------------------------------------------------------------------------
  Widget _buildSlide1LightForThePath() {
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
                        // Glowing Cross Emblem Medallion
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
                            child: Icon(Icons.menu_book_rounded, color: Color(0xFF030D10), size: 28),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Scripture citation
                        const Text(
                          '— መዝሙር ፻፲፱:፻፭',
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
                              fontSize: 16,
                              height: 1.7,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                            children: [
                              const TextSpan(text: 'ሕግህ ለእግሬ '),
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
                                    'መብራት',
                                    style: TextStyle(
                                      fontFamily: 'serif',
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFF3C766),
                                    ),
                                  ),
                                ),
                              ),
                              const TextSpan(text: '\nለመንገዴም '),
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
                                    'ብርሃን',
                                    style: TextStyle(
                                      fontFamily: 'serif',
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF34D399),
                                    ),
                                  ),
                                ),
                              ),
                              const TextSpan(text: ' ነው።'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Text Heading Block
                  const Text(
                    'LIGHT FOR THE PATH',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFE5A93C),
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Scripture in the language\nof your heart.',
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
                    'A quiet, beautiful place to read the Bible in Amharic,\nfollow daily lectionaries, and live in fellowship.',
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
  // SLIDE 2: STUDY DEEPER (የቤተክርስቲያን አበውና 10 ክፍሎች)
  // --------------------------------------------------------------------------
  Widget _buildSlide2StudyDeeper() {
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

                  // Patristics & Root Card
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
                        // Verse with Word Selection Ring
                        const Text(
                          'JOHN 1:1 • ዮሐንስ ፩:፩',
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
                              const TextSpan(text: 'In the beginning was the '),
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
                                    'Word',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFF3C766),
                                    ),
                                  ),
                                ),
                              ),
                              const TextSpan(text: ' , and the Word was with God.'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Concordance Pill
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
                                "STRONG'S G3056 • ግዕዝ: ቃል",
                                style: TextStyle(fontSize: 10, color: Color(0xFFE5A93C), fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'λόγος (Logos)',
                                    style: TextStyle(fontFamily: 'serif', fontSize: 17, color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                  Row(
                                    children: [
                                      _buildFatherBadge('C', 'St. Chrysostom'),
                                      const SizedBox(width: 4),
                                      _buildFatherBadge('A', 'St. Athanasius'),
                                      const SizedBox(width: 4),
                                      _buildFatherBadge('B', 'St. Basil'),
                                      const SizedBox(width: 6),
                                      const Text('Fathers', style: TextStyle(fontSize: 11, color: Colors.white70)),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'logos · Divine Wisdom, Word, Reason',
                                style: TextStyle(fontSize: 11, color: Colors.white60),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  const Text(
                    'STUDY DEEPER',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFE5A93C),
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Study with the whole\nChurch.',
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
                    'Discover the 10 fellowship departments, patristic writings,\nand ask spiritual questions to Confessor Fathers.',
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

  Widget _buildFatherBadge(String initial, String tooltip) {
    return Tooltip(
      message: tooltip,
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFFE5A93C).withOpacity(0.2),
          border: Border.all(color: const Color(0xFFE5A93C), width: 1),
        ),
        child: Center(
          child: Text(
            initial,
            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFFF3C766)),
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // SLIDE 3: EVERY DAY (የዕለቱ ስርዓትና መዝሙር)
  // --------------------------------------------------------------------------
  Widget _buildSlide3DailyRhythm() {
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
                        // Ge'ez Calendar Strip
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.calendar_today_outlined, size: 14, color: Color(0xFFE5A93C)),
                                SizedBox(width: 6),
                                Text(
                                  'የዕለቱ ንባብና ስንክሳር',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFE5A93C)),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text('ጥቅምት ፲፫', style: TextStyle(fontSize: 10, color: Color(0xFF34D399), fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Ge'ez Week Days Ribbon
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildDayChip('ሰ', '11', false),
                            _buildDayChip('ማ', '12', false),
                            _buildDayChip('ረ', '13', true), // Active selected
                            _buildDayChip('ሐ', '14', false),
                            _buildDayChip('ዓ', '15', false),
                            _buildDayChip('ቀ', '16', false),
                            _buildDayChip('እ', '17', false),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Audio Hymn / Mezmur Player Preview
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
                                  const Text(
                                    'ዮሐንስ ፫ • የቅዳሴ ዝማሬ',
                                    style: TextStyle(fontFamily: 'serif', fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                  Text(
                                    _isPlayingAudio ? '0:42 / 3:15' : 'Tap play to hear sample',
                                    style: const TextStyle(fontSize: 10, color: Colors.white60),
                                  ),
                                ],
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
                    'EVERY DAY',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFE5A93C),
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'A daily rhythm of\nworship & reading.',
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
                    'Follow the daily lectionary, hear liturgical hymns,\nand track upcoming Liturgies and fasting seasons.',
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
  // SLIDE 4: MADE FOR YOU (Fanned 3D Stacked Cards)
  // --------------------------------------------------------------------------
  Widget _buildSlide4MakeItYours() {
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

                  // Fanned 3D Perspective Cards
                  SizedBox(
                    height: 180,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Card 1: Parchment & Incense (Left Tilted)
                        Transform(
                          alignment: Alignment.bottomCenter,
                          transform: Matrix4.identity()
                            ..translate(-55.0, 10.0, 0.0)
                            ..rotateZ(-0.14),
                          child: _buildStackCard(
                            title: 'ብራናና ዕጣን',
                            sub: 'Parchment',
                            bgColor: const Color(0xFFF9F5EC),
                            textColor: const Color(0xFF2C2419),
                            accentColor: const Color(0xFFB45309),
                          ),
                        ),

                        // Card 3: Axumite Emerald (Right Tilted)
                        Transform(
                          alignment: Alignment.bottomCenter,
                          transform: Matrix4.identity()
                            ..translate(55.0, 10.0, 0.0)
                            ..rotateZ(0.14),
                          child: _buildStackCard(
                            title: 'አክሱማዊ',
                            sub: 'Emerald',
                            bgColor: const Color(0xFF042018),
                            textColor: Colors.white,
                            accentColor: const Color(0xFF10B981),
                          ),
                        ),

                        // Card 2: Midnight Fellowship (Center Elevated)
                        Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()..translate(0.0, -10.0, 0.0),
                          child: _buildStackCard(
                            title: 'መንፈሳዊ አንድነት',
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

                  const SizedBox(height: 12),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('FOCUS', style: TextStyle(fontSize: 10, letterSpacing: 1.5, color: Colors.white60, fontWeight: FontWeight.bold)),
                      SizedBox(width: 8),
                      Text('•', style: TextStyle(color: Color(0xFFE5A93C))),
                      SizedBox(width: 8),
                      Text('THEME', style: TextStyle(fontSize: 10, letterSpacing: 1.5, color: Colors.white60, fontWeight: FontWeight.bold)),
                      SizedBox(width: 8),
                      Text('•', style: TextStyle(color: Color(0xFFE5A93C))),
                      Text('FONT', style: TextStyle(fontSize: 10, letterSpacing: 1.5, color: Colors.white60, fontWeight: FontWeight.bold)),
                    ],
                  ),

                  const Spacer(),

                  const Text(
                    'MADE FOR YOU',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFE5A93C),
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Make it yours.',
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
                    'Choose your primary fellowship focus, a daily reminder\nand a look that feels sacred. It takes about a minute.',
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
              _buildStepIndicator(1, 'Daily'),
              _buildStepDivider(),
              _buildStepIndicator(2, 'Look'),
            ],
          ),
          const SizedBox(height: 20),

          if (_wizardStep == 0) _buildWizardStep1Focus(),
          if (_wizardStep == 1) _buildWizardStep2Daily(),
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

  // WIZARD STEP 1: CHOOSE FOCUS
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

  // WIZARD STEP 2: DAILY READING & LITURGY
  Widget _buildWizardStep2Daily() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'YOUR DAILY READING',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFFE5A93C), letterSpacing: 2.0),
        ),
        const SizedBox(height: 6),
        const Text(
          'Follow the daily readings.',
          style: TextStyle(fontFamily: 'serif', fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 4),
        const Text(
          'Choose the liturgical lectionary. You can view the full Ethiopian Orthodox calendar inside the app.',
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
                      'ኦርቶዶክስ ተዋሕዶ (Orthodox Tewahedo)',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFF3C766)),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Daily Synaxarium (ስንክሳር), Liturgy & Gospel readings',
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

        // Daily reminder toggle card
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
                      'Daily Reading Reminder',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'A quiet note, once a day (07:00 AM).',
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

  // WIZARD STEP 3: SACRED LOOK (LIVE PREVIEW & PALETTES)
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
          'Shape your reading room.',
          style: TextStyle(fontFamily: 'serif', fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 4),
        const Text(
          'Pick a sacred palette and font size. See it rendered on a real verse.',
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
                  Text(
                    'ዮሐንስ ፩:፲፬ • John 1:14',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _selectedPalette == AppThemePalette.parchmentIncense ? const Color(0xFFB45309) : const Color(0xFFE5A93C),
                    ),
                  ),
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

          // Primary Action Button (Continue > / Set up my Bible > / Enter Fellowship >)
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
