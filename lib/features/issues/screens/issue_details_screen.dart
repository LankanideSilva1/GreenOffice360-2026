import 'dart:io';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../controllers/issue_details_controller.dart';
import '../providers/issue_provider.dart';
import 'location_picker_screen.dart';

class IssueDetailsScreen extends StatefulWidget {
  const IssueDetailsScreen({super.key, this.selectedCategory = 'Water'});

  final String selectedCategory;

  @override
  State<IssueDetailsScreen> createState() => _IssueDetailsScreenState();
}

class _IssueDetailsScreenState extends State<IssueDetailsScreen> {
  final IssueDetailsController _controller = IssueDetailsController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  String _selectedPriority = 'High';
  File? _selectedPhoto;

  final List<String> _priorities = ['Low', 'Medium', 'High', 'Critical'];

  Future<void> _handleTakePhoto() async {
    final photo = await _controller.takePhoto();
    if (!mounted) return;

    if (photo != null) {
      setState(() => _selectedPhoto = photo);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo captured successfully.')),
      );
    }
  }

  Future<void> _handlePickFromGallery() async {
    final photo = await _controller.pickFromGallery();
    if (!mounted) return;

    if (photo != null) {
      setState(() => _selectedPhoto = photo);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image selected from gallery.')),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _restoreLostPhoto();
  }

  Future<void> _restoreLostPhoto() async {
    final photo = await _controller.recoverLostPhoto();
    if (!mounted || photo == null) return;

    setState(() => _selectedPhoto = photo);
  }

  Future<void> _openLocationPicker({bool useCurrentLocation = false}) async {
    final issueProvider = context.read<IssueProvider>();
    final initialLocation = issueProvider.latitude == null || issueProvider.longitude == null
        ? null
        : LatLng(issueProvider.latitude!, issueProvider.longitude!);
    final result = await Navigator.push<MapLocationResult>(
      context,
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          initialLocation: initialLocation,
          useCurrentLocation: useCurrentLocation,
        ),
      ),
    );
    if (!mounted || result == null) return;

    issueProvider.setLocation(
      latitude: result.location.latitude,
      longitude: result.location.longitude,
    );
    _locationController.text = result.label;
    setState(() {});
  }

  Future<void> _saveIssue() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      _showError('Please enter an issue title.');
      return;
    }

    final issueProvider = context.read<IssueProvider>();
    final saved = await issueProvider.saveIssue(
      category: widget.selectedCategory,
      title: title,
      description: _descriptionController.text.trim(),
      priority: _selectedPriority,
      image: _selectedPhoto,
    );
    if (!mounted) return;

    if (saved) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Issue report saved successfully.')),
      );
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.issueSuccess,
        arguments: issueProvider.createdIssue?.id,
      );
    } else {
      _showError(issueProvider.errorMessage ?? 'Unable to save issue report.');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isLandscape ? 760 : 430),
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isLandscape ? 20 : 18,
                vertical: isLandscape ? 18 : 26,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded),
                        color: AppColors.textDark,
                        splashRadius: 20,
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE9F5EE),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Step 2 of 5',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Issue Details',
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                      letterSpacing: -1.2,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildLabel('Issue Title'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _titleController,
                    hintText: '',
                    minLines: 1,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 16),
                  _buildLabel('Description'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _descriptionController,
                    hintText: '',
                    minLines: 3,
                    maxLines: 5,
                  ),
                  const SizedBox(height: 16),
                  _buildLabel('Category'),
                  const SizedBox(height: 8),
                  Container(
                    height: 52,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.fieldBorder),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: AppColors.softGreen,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.water_drop_outlined,
                            size: 16,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            widget.selectedCategory,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                            ),
                          ),
                        ),
                        // const Icon(
                        //   Icons.keyboard_arrow_down_rounded,
                        //   color: AppColors.textDark,
                        //   size: 24,
                        // ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildLabel('Priority'),
                  const SizedBox(height: 8),
                  Row(
                    children: _priorities.map((priority) {
                      final isSelected = priority == _selectedPriority;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedPriority = priority),
                          child: Container(
                            margin: EdgeInsets.only(
                              right: priority != _priorities.last ? 8 : 0,
                            ),
                            height: 42,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFF2E4B4)
                                  : AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.transparent
                                    : AppColors.fieldBorder,
                              ),
                            ),
                            child: Text(
                              priority,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? AppColors.textDark
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  _buildLabel('Location'),
                  const SizedBox(height: 8),
                  Container(
                    height: 52,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.fieldBorder),
                    ),
                    child: InkWell(
                      onTap: () => _openLocationPicker(),
                      borderRadius: BorderRadius.circular(16),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            color: AppColors.primary,
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _locationController.text.isEmpty
                                  ? 'Tap to set location'
                                  : _locationController.text,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 16,
                                color: _locationController.text.isEmpty
                                    ? AppColors.textSecondary
                                    : AppColors.textDark,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Icon(
                            _locationController.text.isEmpty
                                ? Icons.my_location_outlined
                                : Icons.edit_location_alt_outlined,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    height: 52,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.fieldBorder),
                    ),
                    child: InkWell(
                      onTap: () => _openLocationPicker(useCurrentLocation: true),
                      borderRadius: BorderRadius.circular(16),
                      child: Row(
                        children: const [
                          Icon(
                          Icons.location_on_outlined,
                          color: AppColors.primary,
                          size: 22,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Use Current Location',
                              style: TextStyle(
                                fontSize: 16,
                                color: AppColors.textDark,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.my_location_outlined,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _buildLabel('Add Photo'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Material(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: _handleTakePhoto,
                            child: Container(
                              height: 52,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.fieldBorder),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.photo_camera_outlined, color: AppColors.textDark),
                                  SizedBox(width: 8),
                                  Text(
                                    'Take Photo',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: AppColors.textDark,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Material(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: _handlePickFromGallery,
                            child: Container(
                              height: 52,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.fieldBorder),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.photo_library_outlined, color: AppColors.textDark),
                                  SizedBox(width: 8),
                                  Text(
                                    'From Gallery',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: AppColors.textDark,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_selectedPhoto != null) ...[
                    const SizedBox(height: 18),
                    Container(
                      height: 150,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.fieldBorder),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.file(
                        _selectedPhoto!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 58,
                    child: ElevatedButton(
                      onPressed: context.watch<IssueProvider>().isLoading
                          ? null
                          : _saveIssue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: context.watch<IssueProvider>().isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: AppColors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text(
                              'Save',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textDark,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    int minLines = 1,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.fieldBorder),
      ),
      child: TextField(
        controller: controller,
        minLines: minLines,
        maxLines: maxLines,
        style: const TextStyle(
          fontSize: 16,
          color: AppColors.textDark,
          height: 1.4,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            fontSize: 16,
            color: AppColors.fieldHint,
          ),
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}
