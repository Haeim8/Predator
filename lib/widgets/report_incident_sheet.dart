import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:predator/l10n/app_localizations.dart';
import 'package:uuid/uuid.dart';
import '../core/theme.dart';
import '../models/incident.dart';
import '../services/incident_provider.dart';

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

  IncidentType _selectedType = IncidentType.other;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isAnonymous = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _addressController.dispose();
    _descriptionController.dispose();
    _sourceController.dispose();
    super.dispose();
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
                  primary: PredatorTheme.primaryRed,
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
                  primary: PredatorTheme.primaryRed,
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

    final dateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final incident = Incident(
      id: const Uuid().v4(),
      latitude: widget.currentPosition.latitude,
      longitude: widget.currentPosition.longitude,
      address: _addressController.text.trim(),
      description: _descriptionController.text.trim(),
      type: _selectedType,
      status: IncidentStatus.pending,
      dateTime: dateTime,
      createdAt: DateTime.now(),
      source: _sourceController.text.trim().isEmpty
          ? null
          : _sourceController.text.trim(),
      isAnonymous: _isAnonymous,
    );

    try {
      await context.read<IncidentProvider>().submitIncident(incident);
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
          backgroundColor: PredatorTheme.safeGreen,
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
          content: Text('Error: ${e.toString()}'),
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
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: isDark ? PredatorTheme.darkSurface : Colors.white,
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
                    color: PredatorTheme.primaryRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.add_alert,
                    color: PredatorTheme.primaryRed,
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
                              PredatorTheme.primaryRed.withValues(alpha: 0.2),
                          labelStyle: TextStyle(
                            color: isSelected
                                ? PredatorTheme.primaryRed
                                : isDark
                                    ? Colors.white70
                                    : Colors.black54,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                          side: BorderSide(
                            color: isSelected
                                ? PredatorTheme.primaryRed
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

                    // Address
                    TextFormField(
                      controller: _addressController,
                      decoration: InputDecoration(
                        labelText: l10n.incidentAddress,
                        prefixIcon: const Icon(Icons.location_on_outlined,
                            color: PredatorTheme.primaryRed),
                      ),
                      validator: (value) =>
                          value?.trim().isEmpty == true ? 'Required' : null,
                    )
                        .animate()
                        .fadeIn(delay: 200.ms, duration: 300.ms),

                    const SizedBox(height: 16),

                    // Date & Time
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
                                  color: PredatorTheme.primaryRed,
                                  size: 20,
                                ),
                              ),
                              child: Text(
                                '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                                style: TextStyle(
                                  color:
                                      isDark ? Colors.white : Colors.black87,
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
                                  color: PredatorTheme.primaryRed,
                                  size: 20,
                                ),
                              ),
                              child: Text(
                                _selectedTime.format(context),
                                style: TextStyle(
                                  color:
                                      isDark ? Colors.white : Colors.black87,
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

                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: l10n.incidentDescription,
                        prefixIcon: const Icon(Icons.description_outlined,
                            color: PredatorTheme.primaryRed),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 4,
                      validator: (value) =>
                          value?.trim().isEmpty == true ? 'Required' : null,
                    )
                        .animate()
                        .fadeIn(delay: 400.ms, duration: 300.ms),

                    const SizedBox(height: 16),

                    // Source
                    TextFormField(
                      controller: _sourceController,
                      decoration: InputDecoration(
                        labelText: l10n.incidentSource,
                        hintText: l10n.sourcePlaceholder,
                        prefixIcon: const Icon(Icons.link,
                            color: PredatorTheme.primaryRed),
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 500.ms, duration: 300.ms),

                    const SizedBox(height: 16),

                    // Anonymous toggle
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? PredatorTheme.darkCard
                            : PredatorTheme.lightBg,
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
                              ? 'Your identity will not be shared'
                              : 'Your source will be credited',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white38 : Colors.black38,
                          ),
                        ),
                        value: _isAnonymous,
                        onChanged: (value) {
                          setState(() => _isAnonymous = value);
                        },
                        activeTrackColor: PredatorTheme.primaryRed,
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
    }
  }
}
