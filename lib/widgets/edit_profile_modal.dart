import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/app_models.dart';
import '../models/spiritual_models.dart';
import '../state/fellowship_state.dart';
import '../theme/app_theme.dart';

/// Modal dialog for editing user profile attributes (Full name, Baptismal name, Phone, Dept, Year, Batch, Gender)
class EditProfileModal extends StatefulWidget {
  final FellowshipState state;

  const EditProfileModal({super.key, required this.state});

  /// Static helper to display the modal from any screen
  static Future<void> show(BuildContext context, FellowshipState state) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => EditProfileModal(state: state),
    );
  }

  @override
  State<EditProfileModal> createState() => _EditProfileModalState();
}

class _EditProfileModalState extends State<EditProfileModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _fullNameController;
  late TextEditingController _baptismalNameController;
  late TextEditingController _phoneController;
  late TextEditingController _batchController;

  late String _selectedDepartment;
  late int _selectedAcademicYear;
  late String _selectedGender;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final user = widget.state.currentUser;
    _fullNameController = TextEditingController(text: user.fullName);
    _baptismalNameController = TextEditingController(text: user.baptismalName);
    _phoneController = TextEditingController(text: user.phoneNumber);
    _batchController = TextEditingController(text: user.batchYear.isNotEmpty ? user.batchYear : '2024');

    _selectedDepartment = user.department.isNotEmpty ? user.department : 'Computer Science';
    _selectedAcademicYear = user.academicYear > 0 ? user.academicYear : 1;
    _selectedGender = (user.gender != null && user.gender!.trim().isNotEmpty)
        ? user.gender!.trim().toLowerCase()
        : 'male';
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _baptismalNameController.dispose();
    _phoneController.dispose();
    _batchController.dispose();
    super.dispose();
  }

  String _capitalizeWords(String input) {
    if (input.trim().isEmpty) return input.trim();
    return input.trim().split(RegExp(r'\s+')).map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + (word.length > 1 ? word.substring(1).toLowerCase() : '');
    }).join(' ');
  }

  Future<void> _openDepartmentPicker() async {
    final searchCtrl = TextEditingController();
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final query = searchCtrl.text.trim().toLowerCase();
            final filtered = WcuDepartments.all.where((d) => d.toLowerCase().contains(query)).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.72,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context).dividerColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Select Academic Department',
                        style: TextStyle(
                          fontFamily: 'serif',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: searchCtrl,
                    onChanged: (_) => setModalState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Search department...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.4),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: filtered.isEmpty
                        ? const Center(child: Text('No department found.'))
                        : ListView.builder(
                            itemCount: filtered.length,
                            itemBuilder: (ctx, i) {
                              final dept = filtered[i];
                              final isSelected = dept == _selectedDepartment;
                              return ListTile(
                                dense: true,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                tileColor: isSelected ? Theme.of(context).colorScheme.primary.withOpacity(0.12) : null,
                                leading: Icon(
                                  isSelected ? Icons.check_circle : Icons.school_outlined,
                                  color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).iconTheme.color?.withOpacity(0.6),
                                  size: 18,
                                ),
                                title: Text(
                                  dept,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                                onTap: () => Navigator.pop(ctx, dept),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (selected != null && mounted) {
      setState(() => _selectedDepartment = selected);
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final formattedName = _capitalizeWords(_fullNameController.text);
      final formattedBaptismal = _capitalizeWords(_baptismalNameController.text);
      final formattedBatch = _batchController.text.trim().isEmpty ? '2024' : _batchController.text.trim();

      await widget.state.saveUserProfile(
        fullName: formattedName,
        baptismalName: formattedBaptismal,
        phoneNumber: _phoneController.text.trim(),
        department: _selectedDepartment,
        academicYear: _selectedAcademicYear,
        batchYear: formattedBatch,
        gender: _selectedGender,
      );

      HapticFeedback.mediumImpact();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.emerald,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Profile updated successfully • መገለጫዎ ተስተካክሏል',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorMessage = 'Could not save profile: ${e.toString().replaceAll(RegExp(r'\[.*?\]'), '').trim()}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: primaryAccent.withOpacity(0.4), width: 1.5)),
      ),
      padding: EdgeInsets.only(
        top: 16,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle pill
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: primaryAccent.withOpacity(0.14),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.edit_note_rounded, color: primaryAccent, size: 22),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Edit Profile • መገለጫ አርትዕ',
                        style: TextStyle(
                          fontFamily: 'serif',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Update your fellowship identity and campus records. Changes sync across all services.',
                style: TextStyle(fontSize: 11, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary),
              ),
              const SizedBox(height: 18),

              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: AppTheme.crimson.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.crimson.withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppTheme.crimson, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: AppTheme.crimson, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // 1. Full Name
              _buildFieldLabel('Full Name / ሙሉ ስም *', Icons.person_outline),
              const SizedBox(height: 6),
              TextFormField(
                controller: _fullNameController,
                textCapitalization: TextCapitalization.words,
                decoration: _inputDecoration(context, 'e.g. Natnael Daniel'),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter your full name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // 2. Baptismal Name
              _buildFieldLabel('Baptismal Name / የክርስትና ስም', Icons.water_drop_outlined),
              const SizedBox(height: 6),
              TextFormField(
                controller: _baptismalNameController,
                textCapitalization: TextCapitalization.words,
                decoration: _inputDecoration(context, 'e.g. Haile Maryam'),
              ),
              const SizedBox(height: 14),

              // 3. Phone Number
              _buildFieldLabel('Phone Number / ስልክ ቁጥር', Icons.phone_outlined),
              const SizedBox(height: 6),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: _inputDecoration(context, 'e.g. +251911223344'),
              ),
              const SizedBox(height: 14),

              // 4. Department Selector
              _buildFieldLabel('Department / የትምህርት ክፍል', Icons.school_outlined),
              const SizedBox(height: 6),
              InkWell(
                onTap: _openDepartmentPicker,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.business_outlined, color: primaryAccent, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _selectedDepartment,
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(Icons.arrow_drop_down, color: primaryAccent),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // 5. Academic Year & Batch
              Row(
                children: [
                  // Academic Year
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFieldLabel('Academic Year', Icons.calendar_today_outlined),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: theme.dividerColor),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              value: _selectedAcademicYear,
                              isExpanded: true,
                              items: [1, 2, 3, 4, 5, 6].map((yr) {
                                return DropdownMenuItem<int>(
                                  value: yr,
                                  child: Text('Year $yr (ዓመት $yr)', style: const TextStyle(fontSize: 12)),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedAcademicYear = val);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Batch Year
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFieldLabel('Batch Year', Icons.tag_outlined),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _batchController,
                          keyboardType: TextInputType.number,
                          decoration: _inputDecoration(context, 'e.g. 2024'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // 6. Gender Selection
              _buildFieldLabel('Gender / ጾታ', Icons.people_outline),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('Male / ወንድ')),
                      selected: _selectedGender == 'male',
                      selectedColor: primaryAccent,
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _selectedGender == 'male' ? (isDark ? Colors.black : Colors.white) : theme.colorScheme.onSurface,
                      ),
                      onSelected: (val) {
                        if (val) setState(() => _selectedGender = 'male');
                      },
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('Female / ሴት')),
                      selected: _selectedGender == 'female',
                      selectedColor: primaryAccent,
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _selectedGender == 'female' ? (isDark ? Colors.black : Colors.white) : theme.colorScheme.onSurface,
                      ),
                      onSelected: (val) {
                        if (val) setState(() => _selectedGender = 'female');
                      },
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSaving ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        side: BorderSide(color: theme.dividerColor),
                      ),
                      child: Text('Cancel', style: TextStyle(color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _handleSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryAccent,
                        foregroundColor: isDark ? Colors.black : Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 2,
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text(
                              'Save Changes / መገለጫ አስቀምጥ',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label, IconData icon) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 14, color: theme.colorScheme.primary),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(BuildContext context, String hint) {
    final theme = Theme.of(context);
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5) ?? AppTheme.textTertiary, fontSize: 12),
      filled: true,
      fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: theme.dividerColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: theme.dividerColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
      ),
    );
  }
}
