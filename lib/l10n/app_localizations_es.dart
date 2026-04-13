// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appName => 'Vigile';

  @override
  String get onboardingTitle1 => 'Protege Tu Comunidad';

  @override
  String get onboardingDesc1 =>
      'Predator te alerta sobre zonas donde se han reportado crímenes sexuales o violentos contra mujeres y niños en Europa.';

  @override
  String get onboardingTitle2 => 'Todos Pueden Participar';

  @override
  String get onboardingDesc2 =>
      'Reporta incidentes de forma anónima. Nuestro equipo verifica cada reporte antes de que aparezca en el mapa. Gratis y siempre disponible.';

  @override
  String get acceptTerms => 'Aceptar Términos';

  @override
  String get termsTitle => 'Términos de Uso';

  @override
  String get termsContent =>
      'Al usar Predator, reconoces que:\n\n• La información mostrada es solo con fines preventivos\n• No se divulgan datos personales (nombre, dirección)\n• Los eventos son verificados por nuestro equipo de moderación\n• La app y sus creadores no son responsables de las acciones tomadas\n• Los reportes falsos pueden tener consecuencias legales\n• Esta app respeta las leyes europeas de privacidad (RGPD)';

  @override
  String get iAccept => 'Acepto';

  @override
  String get iDecline => 'Rechazo';

  @override
  String get getStarted => 'Comenzar';

  @override
  String get next => 'Siguiente';

  @override
  String get skip => 'Saltar';

  @override
  String get locationPermissionTitle => 'Ubicación Requerida';

  @override
  String get locationPermissionDesc =>
      'Predator necesita tu ubicación para mostrar alertas cercanas.';

  @override
  String get enableLocation => 'Activar Ubicación';

  @override
  String get locationDenied =>
      'Se requiere acceso a la ubicación para usar Predator. Actívalo en configuración.';

  @override
  String get openSettings => 'Abrir Configuración';

  @override
  String get searchPlaceholder => 'Buscar ciudad o dirección...';

  @override
  String get reportIncident => 'Reportar un Incidente';

  @override
  String get incidentAddress => 'Dirección / Lugar';

  @override
  String get incidentDate => 'Fecha y Hora';

  @override
  String get incidentDescription => 'Describe lo que pasó';

  @override
  String get incidentSource => 'Fuente (opcional)';

  @override
  String get sourcePlaceholder => 'Instagram, enlace periodista, medios...';

  @override
  String get anonymous => 'Permanecer Anónimo';

  @override
  String get submitReport => 'Enviar Reporte';

  @override
  String get reportSubmitted => 'Reporte enviado para verificación';

  @override
  String get pendingVerification => 'Pendiente de Verificación';

  @override
  String get verified => 'Verificado';

  @override
  String get incidentDetails => 'Detalles del Incidente';

  @override
  String get reportedOn => 'Reportado el';

  @override
  String get nearYou => 'Cerca de Ti';

  @override
  String get freeApp => '100% Gratis';

  @override
  String get communityDriven => 'Comunitario';

  @override
  String get alwaysAvailable => 'Siempre Disponible';

  @override
  String get cancel => 'Cancelar';

  @override
  String get close => 'Cerrar';

  @override
  String get incidentType => 'Tipo de incidente';

  @override
  String get sexualAssault => 'Agresión Sexual';

  @override
  String get harassment => 'Acoso';

  @override
  String get violence => 'Violencia contra Mujeres/Niños';

  @override
  String get other => 'Otro';

  @override
  String get alertNearby => 'Alerta: Incidente reportado cerca';
}
