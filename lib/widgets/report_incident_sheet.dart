import 'dart:io';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:predator/l10n/app_localizations.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../core/theme.dart';
import '../models/incident.dart';
import '../models/convicted_person.dart';
import '../services/incident_provider.dart';
import '../services/firestore_service.dart';

class ReportIncidentSheet extends StatefulWidget {
  final LatLng currentPosition;
  final VoidCallback onSubmitted;

  const ReportIncidentSheet({
    super.key,
    required this.currentPosition,
    required this.onSubmitted,
  });

  @override
  State<ReportIncidentSheet> createState() => _ReportIncidentSheetState();
}

class _ReportIncidentSheetState extends State<ReportIncidentSheet> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _sourceController = TextEditingController();
  final _socialMediaController = TextEditingController();
  // Champs individu
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _factsController = TextEditingController();
  final _instagramController = TextEditingController();
  final _twitterController = TextEditingController();
  final _linkedinController = TextEditingController();
  DateTime? _convictionDate;
  final ImagePicker _picker = ImagePicker();

  IncidentType _selectedType = IncidentType.other;
  DangerLevel _selectedDanger = DangerLevel.vigilance;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isAnonymous = true;
  bool _isSubmitting = false;
  final List<XFile> _selectedMedia = [];

  @override
  void dispose() {
    _addressController.dispose();
    _descriptionController.dispose();
    _sourceController.dispose();
    _socialMediaController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _factsController.dispose();
    _instagramController.dispose();
    _twitterController.dispose();
    _linkedinController.dispose();
    super.dispose();
  }

  static const int _maxMedia = 3;
  static const double _maxImageWidth = 1280;
  static const double _maxImageHeight = 720;
  static const int _imageQuality = 70;
  static const int _maxVideoDurationSec = 120;

  bool get _canAddMedia => _selectedMedia.length < _maxMedia;

  Future<void> _pickPhoto() async {
    if (!_canAddMedia) return;
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: _maxImageWidth,
      maxHeight: _maxImageHeight,
      imageQuality: _imageQuality,
    );
    if (image != null) {
      setState(() => _selectedMedia.add(image));
    }
  }

  Future<void> _pickVideo() async {
    if (!_canAddMedia) return;
    final video = await _picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(seconds: _maxVideoDurationSec),
    );
    if (video != null) {
      setState(() => _selectedMedia.add(video));
    }
  }

  Future<void> _takePhoto() async {
    if (!_canAddMedia) return;
    final image = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: _maxImageWidth,
      maxHeight: _maxImageHeight,
      imageQuality: _imageQuality,
    );
    if (image != null) {
      setState(() => _selectedMedia.add(image));
    }
  }

  void _removeMedia(int index) {
    setState(() => _selectedMedia.removeAt(index));
  }

  void _showMediaPicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? VigileTheme.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library,
                    color: VigileTheme.primaryRed),
                title: const Text('Photo depuis la galerie'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickPhoto();
                },
              ),
              ListTile(
                leading: const Icon(Icons.videocam,
                    color: VigileTheme.primaryRed),
                title: const Text('Vidéo depuis la galerie'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickVideo();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt,
                    color: VigileTheme.primaryRed),
                title: const Text('Prendre une photo'),
                onTap: () {
                  Navigator.pop(ctx);
                  _takePhoto();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<List<String>> _uploadMedia(String itemId, {String storagePath = 'incidents'}) async {
    final List<String> urls = [];
    final storage = FirebaseStorage.instance;

    for (int i = 0; i < _selectedMedia.length; i++) {
      final file = _selectedMedia[i];
      final ext = file.path.split('.').last.toLowerCase();
      final isVideo = ['mp4', 'mov', 'avi'].contains(ext);
      final contentType = isVideo ? 'video/$ext' : 'image/jpeg';

      final ref = storage.ref('$storagePath/$itemId/media_$i.$ext');
      await ref.putFile(
        File(file.path),
        SettableMetadata(
          contentType: contentType,
          cacheControl: 'public, max-age=31536000', // Cache 1 an
        ),
      );
      final url = await ref.getDownloadURL();
      urls.add(url);
    }

    return urls;
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: VigileTheme.primaryRed,
                ),
          ),
          child: child!,
        );
      },
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: VigileTheme.primaryRed,
                ),
          ),
          child: child!,
        );
      },
    );
    if (time != null) {
      setState(() => _selectedTime = time);
    }
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final itemId = const Uuid().v4();
    final provider = context.read<IncidentProvider>();

    try {
      // Upload des médias si présents
      List<String> mediaUrls = [];
      if (_selectedMedia.isNotEmpty) {
        final storagePath = _selectedType == IncidentType.individual
            ? 'convicted_persons' : 'incidents';
        mediaUrls = await _uploadMedia(itemId, storagePath: storagePath);
      }

      if (_selectedType == IncidentType.individual) {
        // Soumettre comme personne condamnée
        final person = ConvictedPerson(
          id: itemId,
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          facts: _factsController.text.trim(),
          convictionDate: _convictionDate,
          address: _addressController.text.trim().isEmpty
              ? null : _addressController.text.trim(),
          mediaUrls: mediaUrls,
          instagram: _instagramController.text.trim().isEmpty
              ? null : _instagramController.text.trim(),
          twitter: _twitterController.text.trim().isEmpty
              ? null : _twitterController.text.trim(),
          linkedin: _linkedinController.text.trim().isEmpty
              ? null : _linkedinController.text.trim(),
          isAnonymous: _isAnonymous,
          createdAt: DateTime.now(),
        );
        await FirestoreService().submitPerson(person);
      } else {
        // Soumettre comme incident normal
        final dateTime = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          _selectedTime.hour,
          _selectedTime.minute,
        );

        final incident = Incident(
          id: itemId,
          latitude: widget.currentPosition.latitude,
          longitude: widget.currentPosition.longitude,
          address: _addressController.text.trim(),
          description: _descriptionController.text.trim(),
          type: _selectedType,
          dangerLevel: _selectedDanger,
          status: IncidentStatus.pending,
          dateTime: dateTime,
          createdAt: DateTime.now(),
          source: _sourceController.text.trim().isEmpty
              ? null
              : _sourceController.text.trim(),
          isAnonymous: _isAnonymous,
          mediaUrls: mediaUrls,
          socialMediaUrl: _socialMediaController.text.trim().isEmpty
              ? null
              : _socialMediaController.text.trim(),
        );

        await provider.submitIncident(incident);
      }
      if (!mounted) return;
      widget.onSubmitted();
      Navigator.of(context).pop();

      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Text(l10n.reportSubmitted)),
            ],
          ),
          backgroundColor: VigileTheme.safeGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: BoxDecoration(
        color: isDark ? VigileTheme.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: VigileTheme.primaryRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.add_alert,
                    color: VigileTheme.primaryRed,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Text(
                  l10n.reportIncident,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(
                    Icons.close,
                    color: isDark ? Colors.white54 : Colors.black45,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 300.ms),

          // Form
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Incident type selector
                    Text(
                      l10n.incidentType,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: IncidentType.values.map((type) {
                        final isSelected = _selectedType == type;
                        return ChoiceChip(
                          label: Text(_getTypeText(type, l10n)),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _selectedType = type);
                            }
                          },
                          selectedColor:
                              VigileTheme.primaryRed.withValues(alpha: 0.2),
                          labelStyle: TextStyle(
                            color: isSelected
                                ? VigileTheme.primaryRed
                                : isDark
                                    ? Colors.white70
                                    : Colors.black54,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                          side: BorderSide(
                            color: isSelected
                                ? VigileTheme.primaryRed
                                : isDark
                                    ? Colors.white12
                                    : Colors.black12,
                          ),
                        );
                      }).toList(),
                    )
                        .animate()
                        .fadeIn(delay: 100.ms, duration: 300.ms),

                    const SizedBox(height: 20),

                    // Niveau de dangerosité
                    if (_selectedType != IncidentType.individual) ...[
                      Text(
                        'Niveau de dangerosité',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: DangerLevel.values.map((level) {
                          final isSelected = _selectedDanger == level;
                          final color = _getDangerColor(level);
                          final label = _getDangerLabel(level);
                          return Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedDanger = level),
                              child: Container(
                                margin: EdgeInsets.only(
                                    right: level != DangerLevel.urgence ? 6 : 0),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? color.withValues(alpha: 0.2)
                                      : isDark
                                          ? Colors.white.withValues(alpha: 0.05)
                                          : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected ? color : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      '${level.index + 1}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: isSelected ? color : Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      label,
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w600,
                                        color: isSelected ? color : Colors.grey,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ).animate().fadeIn(delay: 150.ms, duration: 300.ms),
                      const SizedBox(height: 20),
                    ],

                    // === FORMULAIRE INDIVIDU ===
                    if (_selectedType == IncidentType.individual) ...[
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _lastNameController,
                              maxLength: 100,
                              decoration: const InputDecoration(
                                labelText: 'Nom *',
                                prefixIcon: Icon(Icons.person, color: VigileTheme.primaryRed),
                                counterText: '',
                              ),
                              validator: (v) => v!.trim().isEmpty ? 'Requis' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _firstNameController,
                              maxLength: 100,
                              decoration: const InputDecoration(
                                labelText: 'Prénom *',
                                prefixIcon: Icon(Icons.person_outline, color: VigileTheme.primaryRed),
                                counterText: '',
                              ),
                              validator: (v) => v!.trim().isEmpty ? 'Requis' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _factsController,
                        maxLength: 1000,
                        decoration: const InputDecoration(
                          labelText: 'Faits reprochés / condamnation *',
                          prefixIcon: Icon(Icons.gavel, color: VigileTheme.primaryRed),
                          alignLabelWithHint: true,
                          counterText: '',
                        ),
                        maxLines: 4,
                        validator: (v) => v!.trim().isEmpty ? 'Requis' : null,
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(1990),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) setState(() => _convictionDate = date);
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Date de condamnation',
                            prefixIcon: Icon(Icons.calendar_today, color: VigileTheme.primaryRed, size: 20),
                          ),
                          child: Text(
                            _convictionDate != null
                                ? '${_convictionDate!.day}/${_convictionDate!.month}/${_convictionDate!.year}'
                                : 'Sélectionner',
                            style: TextStyle(color: _convictionDate != null ? (isDark ? Colors.white : Colors.black87) : Colors.grey),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _addressController,
                        maxLength: 200,
                        decoration: const InputDecoration(
                          labelText: 'Adresse connue (optionnel)',
                          prefixIcon: Icon(Icons.location_on, color: VigileTheme.primaryRed),
                          counterText: '',
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text('Réseaux sociaux de l\'individu',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white70 : Colors.black54)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _instagramController,
                        maxLength: 100,
                        decoration: const InputDecoration(
                          labelText: 'Instagram',
                          prefixIcon: Icon(Icons.camera_alt, color: VigileTheme.primaryRed),
                          counterText: '',
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _twitterController,
                        maxLength: 100,
                        decoration: const InputDecoration(
                          labelText: 'X (Twitter)',
                          prefixIcon: Icon(Icons.alternate_email, color: VigileTheme.primaryRed),
                          counterText: '',
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _linkedinController,
                        maxLength: 100,
                        decoration: const InputDecoration(
                          labelText: 'LinkedIn',
                          prefixIcon: Icon(Icons.work, color: VigileTheme.primaryRed),
                          counterText: '',
                        ),
                      ),
                    ] else ...[
                      // === FORMULAIRE INCIDENT NORMAL ===
                      TextFormField(
                        controller: _addressController,
                        maxLength: 200,
                        decoration: InputDecoration(
                          labelText: l10n.incidentAddress,
                          prefixIcon: const Icon(Icons.location_on_outlined,
                              color: VigileTheme.primaryRed),
                          counterText: '',
                        ),
                        validator: (value) =>
                            value?.trim().isEmpty == true ? 'Requis' : null,
                      )
                          .animate()
                          .fadeIn(delay: 200.ms, duration: 300.ms),

                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: _selectDate,
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: l10n.incidentDate,
                                  prefixIcon: const Icon(
                                    Icons.calendar_today,
                                    color: VigileTheme.primaryRed,
                                    size: 20,
                                  ),
                                ),
                                child: Text(
                                  '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                                  style: TextStyle(
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              onTap: _selectTime,
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  prefixIcon: Icon(
                                    Icons.access_time,
                                    color: VigileTheme.primaryRed,
                                    size: 20,
                                  ),
                                ),
                                child: Text(
                                  _selectedTime.format(context),
                                  style: TextStyle(
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                          .animate()
                          .fadeIn(delay: 300.ms, duration: 300.ms),

                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _descriptionController,
                        maxLength: 500,
                        decoration: InputDecoration(
                          labelText: l10n.incidentDescription,
                          prefixIcon: const Icon(Icons.description_outlined,
                              color: VigileTheme.primaryRed),
                          alignLabelWithHint: true,
                          counterText: '',
                        ),
                        maxLines: 4,
                        validator: (value) =>
                            value?.trim().isEmpty == true ? 'Requis' : null,
                      )
                          .animate()
                          .fadeIn(delay: 400.ms, duration: 300.ms),
                    ],

                    const SizedBox(height: 16),

                    // ── Médias (photo/vidéo) ──
                    Text(
                      'Preuves (photo / vidéo)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 100,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          // Bouton ajouter
                          GestureDetector(
                            onTap: _canAddMedia ? _showMediaPicker : null,
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? VigileTheme.darkCard
                                    : VigileTheme.lightBg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _canAddMedia
                                      ? VigileTheme.primaryRed
                                          .withValues(alpha: 0.3)
                                      : Colors.grey.withValues(alpha: 0.2),
                                  width: 1.5,
                                  strokeAlign: BorderSide.strokeAlignInside,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_a_photo,
                                      color: _canAddMedia
                                          ? VigileTheme.primaryRed
                                          : Colors.grey,
                                      size: 28),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${_selectedMedia.length}/$_maxMedia',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark
                                          ? Colors.white54
                                          : Colors.black45,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Médias sélectionnés
                          ..._selectedMedia.asMap().entries.map((entry) {
                            final index = entry.key;
                            final file = entry.value;
                            final isVideo = file.path.endsWith('.mp4') ||
                                file.path.endsWith('.mov') ||
                                file.path.endsWith('.avi');
                            return Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Stack(
                                children: [
                                  Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      image: isVideo
                                          ? null
                                          : DecorationImage(
                                              image:
                                                  FileImage(File(file.path)),
                                              fit: BoxFit.cover,
                                            ),
                                      color: isVideo
                                          ? (isDark
                                              ? VigileTheme.darkCard
                                              : Colors.grey[200])
                                          : null,
                                    ),
                                    child: isVideo
                                        ? const Center(
                                            child: Icon(
                                              Icons.videocam,
                                              color: VigileTheme.primaryRed,
                                              size: 36,
                                            ),
                                          )
                                        : null,
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap: () => _removeMedia(index),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.close,
                                            color: Colors.white, size: 14),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ).animate().fadeIn(delay: 450.ms, duration: 300.ms),

                    const SizedBox(height: 16),

                    // ── Lien réseau social ──
                    TextFormField(
                      controller: _socialMediaController,
                      maxLength: 200,
                      decoration: InputDecoration(
                        labelText: 'Lien réseau social',
                        hintText: 'Instagram, TikTok, X, Facebook...',
                        prefixIcon: const Icon(Icons.share,
                            color: VigileTheme.primaryRed),
                        counterText: '',
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 500.ms, duration: 300.ms),

                    const SizedBox(height: 16),

                    // Source
                    TextFormField(
                      controller: _sourceController,
                      maxLength: 200,
                      decoration: InputDecoration(
                        labelText: l10n.incidentSource,
                        hintText: l10n.sourcePlaceholder,
                        prefixIcon: const Icon(Icons.link,
                            color: VigileTheme.primaryRed),
                        counterText: '',
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 550.ms, duration: 300.ms),

                    const SizedBox(height: 16),

                    // Anonymous toggle
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? VigileTheme.darkCard
                            : VigileTheme.lightBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: SwitchListTile(
                        title: Text(
                          l10n.anonymous,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        subtitle: Text(
                          _isAnonymous
                              ? 'Votre identité ne sera pas partagée'
                              : 'Votre source sera créditée',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white38 : Colors.black38,
                          ),
                        ),
                        value: _isAnonymous,
                        onChanged: (value) {
                          setState(() => _isAnonymous = value);
                        },
                        activeTrackColor: VigileTheme.primaryRed,
                        contentPadding: EdgeInsets.zero,
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 600.ms, duration: 300.ms),

                    const SizedBox(height: 24),

                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitReport,
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.send, size: 20),
                                  const SizedBox(width: 10),
                                  Text(
                                    l10n.submitReport,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 700.ms, duration: 300.ms),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getTypeText(IncidentType type, AppLocalizations l10n) {
    switch (type) {
      case IncidentType.sexualAssault:
        return l10n.sexualAssault;
      case IncidentType.harassment:
        return l10n.harassment;
      case IncidentType.violence:
        return l10n.violence;
      case IncidentType.other:
        return l10n.other;
      case IncidentType.individual:
        return 'Individu';
    }
  }

  Color _getDangerColor(DangerLevel level) {
    switch (level) {
      case DangerLevel.vigilance:
        return Colors.green;
      case DangerLevel.risque:
        return const Color(0xFFFFD600);
      case DangerLevel.incident:
        return const Color(0xFFE65100);
      case DangerLevel.urgence:
        return const Color(0xFFB71C1C);
    }
  }

  String _getDangerLabel(DangerLevel level) {
    switch (level) {
      case DangerLevel.vigilance:
        return 'Vigilance';
      case DangerLevel.risque:
        return 'Risque';
      case DangerLevel.incident:
        return 'Incident';
      case DangerLevel.urgence:
        return 'Urgence';
    }
  }
}
