// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Predator';

  @override
  String get onboardingTitle1 => 'Protect Your Community';

  @override
  String get onboardingDesc1 =>
      'Predator alerts you about areas where sexual or violent crimes against women and children have been reported in Europe.';

  @override
  String get onboardingTitle2 => 'Everyone Can Participate';

  @override
  String get onboardingDesc2 =>
      'Report incidents anonymously. Our team verifies every report before it appears on the map. Free and always available.';

  @override
  String get acceptTerms => 'Accept Terms of Use';

  @override
  String get termsTitle => 'Terms of Use';

  @override
  String get termsContent =>
      'By using Predator, you acknowledge that:\n\n• Information displayed is for prevention purposes only\n• No personal data (name, address) of any individual is disclosed\n• Events shown are verified by our moderation team\n• The app and its creators are not liable for actions taken based on this information\n• False reporting may result in legal consequences\n• This app respects European privacy laws (GDPR)';

  @override
  String get iAccept => 'I Accept';

  @override
  String get iDecline => 'I Decline';

  @override
  String get getStarted => 'Get Started';

  @override
  String get next => 'Next';

  @override
  String get skip => 'Skip';

  @override
  String get locationPermissionTitle => 'Location Required';

  @override
  String get locationPermissionDesc =>
      'Predator needs your location to show nearby alerts and keep you informed about your surroundings.';

  @override
  String get enableLocation => 'Enable Location';

  @override
  String get locationDenied =>
      'Location access is required to use Predator. Please enable it in your device settings.';

  @override
  String get openSettings => 'Open Settings';

  @override
  String get searchPlaceholder => 'Search city or address...';

  @override
  String get reportIncident => 'Report an Incident';

  @override
  String get incidentAddress => 'Address / Location';

  @override
  String get incidentDate => 'Date & Time';

  @override
  String get incidentDescription => 'Describe what happened';

  @override
  String get incidentSource => 'Source (optional)';

  @override
  String get sourcePlaceholder => 'Instagram, journalist link, media...';

  @override
  String get anonymous => 'Stay Anonymous';

  @override
  String get submitReport => 'Submit Report';

  @override
  String get reportSubmitted => 'Report submitted for verification';

  @override
  String get pendingVerification => 'Pending Verification';

  @override
  String get verified => 'Verified';

  @override
  String get incidentDetails => 'Incident Details';

  @override
  String get reportedOn => 'Reported on';

  @override
  String get nearYou => 'Near You';

  @override
  String get freeApp => '100% Free';

  @override
  String get communityDriven => 'Community Driven';

  @override
  String get alwaysAvailable => 'Always Available';

  @override
  String get cancel => 'Cancel';

  @override
  String get close => 'Close';

  @override
  String get incidentType => 'Type of incident';

  @override
  String get sexualAssault => 'Sexual Assault';

  @override
  String get harassment => 'Harassment';

  @override
  String get violence => 'Violence Against Women/Children';

  @override
  String get other => 'Other';

  @override
  String get alertNearby => 'Alert: Incident reported nearby';
}
