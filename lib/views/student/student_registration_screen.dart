import 'package:flutter/material.dart';
import '../../state/fellowship_state.dart';
import '../../theme/app_theme.dart';

class StudentRegistrationScreen extends StatefulWidget {
  final FellowshipState state;
  final VoidCallback onRegistered;

  const StudentRegistrationScreen({
    super.key,
    required this.state,
    required this.onRegistered,
  });

  @override
  State<StudentRegistrationScreen> createState() => _StudentRegistrationScreenState();
}

class _StudentRegistrationScreenState extends State<StudentRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController(text: 'Teklehaimanot Girma');
  final _baptismalNameController = TextEditingController(text: 'Haile Meskel');
  final _phoneController = TextEditingController(text: '+251912345678');
  final _batchYearController = TextEditingController(text: '2024');

  int _selectedAcademicYear = 3;
  String _selectedDepartment = 'Computer Science';

  final List<String> _departments = [
    'Computer Science',
    'Software Engineering',
    'Civil Engineering',
    'Electrical & Computer Eng',
    'Medicine & Health Science',
    'Pharmacy',
    'Law & Governance',
    'Business & Economics',
    'Accounting & Finance',
    'Natural & Computational Science',
    'Theology & Christian Tradition',
  ];

  @override
  void dispose() {
    _fullNameController.dispose();
    _baptismalNameController.dispose();
    _phoneController.dispose();
    _batchYearController.dispose();
    super.dispose();
  }

  void _submitRegistration() {
    if (_formKey.currentState?.validate() ?? false) {
      widget.state.registerStudent(
        fullName: _fullNameController.text.trim(),
        baptismalName: _baptismalNameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        batchYear: _batchYearController.text.trim(),
        department: _selectedDepartment,
        academicYear: _selectedAcademicYear,
      );

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppTheme.surfaceColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.check_circle_outline, color: AppTheme.goldAccent, size: 28),
              SizedBox(width: 10),
              Text(
                'Registration Submitted',
                style: TextStyle(fontSize: 18, color: AppTheme.goldLight, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Text(
            'Welcome ${_fullNameController.text}! Your registration credentials (Baptismal Name: ${_baptismalNameController.text}, Dept: $_selectedDepartment) have been saved. Our fellowship admins will review and assign your spiritual family shortly.',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.5),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                widget.onRegistered();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.goldAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Enter Fellowship Portal', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Header Card matching screen - Copy.png
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.borderMuted.withOpacity(0.6)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.goldAccent.withOpacity(0.15),
                          border: Border.all(color: AppTheme.goldAccent.withOpacity(0.5)),
                        ),
                        child: const Icon(Icons.church_outlined, color: AppTheme.goldLight, size: 26),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Welcome to WCU Fellowship',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'serif',
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Join our spiritual and academic community. We blend the ancient reverence of Orthodox Christianity with modern university life, guiding each other through fellowship, study, and prayer at WCU.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Section: Personal Details
                const Text(
                  'Personal Details',
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.goldLight,
                  ),
                ),
                const SizedBox(height: 14),

                // Full Name Input
                const Text('Full Name', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _fullNameController,
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: 'Enter your full name',
                    prefixIcon: Icon(Icons.person_outline, color: AppTheme.goldAccent, size: 20),
                  ),
                  validator: (val) => val == null || val.isEmpty ? 'Please enter full name' : null,
                ),

                const SizedBox(height: 14),

                // Baptismal Name Input (Christian Name)
                const Text('Baptismal Name', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _baptismalNameController,
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: 'Christian Name (e.g. Haile Meskel, Walata Maryam)',
                    prefixIcon: Icon(Icons.star_border, color: AppTheme.goldAccent, size: 20),
                  ),
                  validator: (val) => val == null || val.isEmpty ? 'Please enter baptismal name' : null,
                ),

                const SizedBox(height: 14),

                // Phone Number Input
                const Text('Phone Number', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: '+251 900 000 000',
                    prefixIcon: Icon(Icons.phone_outlined, color: AppTheme.goldAccent, size: 20),
                  ),
                  validator: (val) => val == null || val.isEmpty ? 'Please enter phone number' : null,
                ),

                const SizedBox(height: 24),

                // Section: Academic Information
                const Text(
                  'Academic Information',
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.goldLight,
                  ),
                ),
                const SizedBox(height: 14),

                // Academic Year (Year 1 to 8 grid/pills)
                const Text('Academic Year', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: List.generate(8, (index) {
                    final year = index + 1;
                    final isSelected = _selectedAcademicYear == year;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedAcademicYear = year),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.goldAccent : AppTheme.secondaryBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? AppTheme.goldLight : AppTheme.borderMuted,
                            width: isSelected ? 1.5 : 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppTheme.goldAccent.withOpacity(0.4),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  )
                                ]
                              : null,
                        ),
                        child: Text(
                          'Year $year',
                          style: TextStyle(
                            color: isSelected ? Colors.black : AppTheme.textPrimary,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 16),

                // Batch Year
                const Text('Batch Year', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _batchYearController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: 'e.g. 2024',
                    prefixIcon: Icon(Icons.calendar_today_outlined, color: AppTheme.goldAccent, size: 20),
                  ),
                ),

                const SizedBox(height: 16),

                // Department Dropdown
                const Text('Department', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.borderMuted),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedDepartment,
                      isExpanded: true,
                      dropdownColor: AppTheme.surfaceColor,
                      icon: const Icon(Icons.keyboard_arrow_down, color: AppTheme.goldAccent),
                      items: _departments.map((dept) {
                        return DropdownMenuItem<String>(
                          value: dept,
                          child: Text(
                            dept,
                            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedDepartment = val);
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Join Fellowship Action Button
                Container(
                  height: 54,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE57E12), Color(0xFFD4690B), Color(0xFFB84E03)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFD4690B).withOpacity(0.4),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _submitRegistration,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Join Fellowship',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
