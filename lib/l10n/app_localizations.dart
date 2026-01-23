import 'package:flutter/material.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  // Helper method for translations
  String _translate(String en, String es, String pl) {
    if (locale.languageCode == 'es') return es;
    if (locale.languageCode == 'pl') return pl;
    return en;
  }

  // Auth Screen
  String get loginTitle => _translate(
    'Welcome to Trip Bud',
    'Bienvenido a Trip Bud',
    'Witaj w Trip Bud',
  );
  String get loginSubtitle => _translate(
    'Plan and track your trips',
    'Planifica y rastrea tus viajes',
    'Planuj i śledź swoje podróże',
  );
  String get emailLabel => _translate('Email', 'Correo Electrónico', 'Email');
  String get passwordLabel => _translate('Password', 'Contraseña', 'Hasło');
  String get loginButton => _translate('Login', 'Inicia Sesión', 'Zaloguj się');
  String get signupButton =>
      _translate('Sign Up', 'Crear Cuenta', 'Utwórz konto');
  String get forgotPassword => _translate(
    'Forgot Password?',
    '¿Olvidaste tu contraseña?',
    'Zapomniałeś hasła?',
  );
  String get dontHaveAccount => _translate(
    "Don't have an account?",
    '¿No tienes cuenta?',
    'Nie masz konta?',
  );
  String get haveAccount => _translate(
    'Already have an account?',
    '¿Ya tienes cuenta?',
    'Masz już konto?',
  );
  String get googleSignIn => _translate(
    'Sign in with Google',
    'Inicia con Google',
    'Zaloguj się za pomocą Google',
  );
  String get orContinueWith => _translate(
    'Or continue with',
    'O continúa con',
    'Lub kontynuuj za pomocą',
  );

  // Register Screen
  String get registerTitle =>
      _translate('Create Account', 'Crear Nueva Cuenta', 'Utwórz konto');
  String get nameLabel =>
      _translate('Full Name', 'Nombre Completo', 'Pełne Imię');
  String get confirmPasswordLabel =>
      _translate('Confirm Password', 'Confirmar Contraseña', 'Potwierdź hasło');
  String get passwordMismatch => _translate(
    'Passwords do not match',
    'Las contraseñas no coinciden',
    'Hasła nie pasują do siebie',
  );
  String get passwordTooShort => _translate(
    'Password must be at least 6 characters',
    'La contraseña debe tener al menos 6 caracteres',
    'Hasło musi zawierać co najmniej 6 znaków',
  );

  // Reset Password
  String get resetPasswordTitle =>
      _translate('Reset Password', 'Recuperar Contraseña', 'Zresetuj hasło');
  String get resetPasswordSubtitle => _translate(
    'Enter your email to receive a reset link',
    'Ingresa tu correo para recibir un enlace de recuperación',
    'Wpisz swój email, aby otrzymać link do resetowania',
  );
  String get sendReset =>
      _translate('Send Link', 'Enviar Enlace', 'Wyślij link');
  String get emailSent =>
      _translate('Email sent', 'Correo enviado', 'Email wysłany');

  // Trip Screens
  String get trips => _translate('Trips', 'Viajes', 'Podróże');
  String get createTrip =>
      _translate('Create Trip', 'Crear Viaje', 'Utwórz podróż');
  String get tripDetails =>
      _translate('Trip Details', 'Detalles del Viaje', 'Szczegóły podróży');
  String get schedule => _translate('Schedule', 'Itinerario', 'Harmonogram');
  String get map => _translate('Map', 'Mapa', 'Mapa');
  String get gallery => _translate('Gallery', 'Galería', 'Galeria');
  String get settings => _translate('Settings', 'Configuración', 'Ustawienia');
  String get logout => _translate('Logout', 'Cerrar Sesión', 'Wyloguj się');
  String get language => _translate('Language', 'Idioma', 'Język');

  // Auth Screen - Additional
  String get allFieldsRequired => _translate(
    'All fields are required',
    'Todos los campos son requeridos',
    'Wszystkie pola są wymagane',
  );
  String get registerSubtitle => _translate(
    'Join us and start planning your adventures',
    'Únete a nosotros y comienza a planificar tus aventuras',
    'Dołącz do nas i zacznij planować swoje przygody',
  );
  String get resetPasswordEnterEmail => _translate(
    'Enter your email and we\'ll send you a link to reset your password',
    'Ingresa tu correo y te enviaremos un enlace para restablecer tu contraseña',
    'Wpisz swój email, a wyślemy Ci link do zresetowania hasła',
  );
  String get pleaseEnterEmail => _translate(
    'Please enter your email',
    'Por favor ingresa tu correo',
    'Proszę wpisz swój email',
  );
  String get passwordResetSent => _translate(
    'Password reset email sent. Check your inbox.',
    'Correo de restablecimiento de contraseña enviado. Revisa tu bandeja de entrada.',
    'Email do zresetowania hasła wysłany. Sprawdź swoją skrzynkę odbiorczą.',
  );
  String get failedToSendReset => _translate(
    'Failed to send reset email. Try again.',
    'Error al enviar correo de restablecimiento. Intenta de nuevo.',
    'Nie udało się wysłać email do resetowania. Spróbuj ponownie.',
  );
  String get anErrorOccurred => _translate(
    'An error occurred: ',
    'Ocurrió un error: ',
    'Wystąpił błąd: ',
  );

  // Trip Screens - Overview
  String get noTripsYet =>
      _translate('No trips yet', 'Sin viajes aún', 'Brak podróży');
  String get createYourFirstTrip => _translate(
    'Create your first trip to get started',
    'Crea tu primer viaje para comenzar',
    'Utwórz swoją pierwszą podróż, aby zacząć',
  );

  // Trip Detail Screen
  String get tripDetailsTitle =>
      _translate('Trip Details', 'Detalles del Viaje', 'Szczegóły podróży');
  String get edit => _translate('Edit', 'Editar', 'Edytuj');
  String get overview => _translate('Overview', 'Descripción', 'Przegląd');
  String get placesOnMap =>
      _translate('places on the map', 'lugares en el mapa', 'miejsc na mapie');
  String get tripDatesLabel =>
      _translate('Trip Dates', 'Fechas del Viaje', 'Daty podróży');
  String get durationLabel =>
      _translate('Duration', 'Duración', 'Czas trwania');
  String get days => _translate('days', 'días', 'dni');
  String get notSet => _translate('Not set', 'No establecido', 'Nie ustawiono');
  String get placesLabel => _translate('Places', 'Lugares', 'Miejsca');
  String get day => _translate('Day', 'Día', 'Dzień');
  String get photos => _translate('photos', 'fotos', 'zdjęć');

  // Schedule Editor
  String get scheduleEditor => _translate(
    'Schedule Editor',
    'Editor de Itinerario',
    'Edytor Harmonogramu',
  );
  String get save => _translate('Save', 'Guardar', 'Zapisz');
  String get totalDays =>
      _translate('Total Days:', 'Días Totales:', 'Razem dni:');
  String get scheduleUpdatedSuccessfully => _translate(
    'Schedule updated successfully',
    'Itinerario actualizado exitosamente',
    'Harmonogram zaktualizowany pomyślnie',
  );
  String get travelToNextPlace => _translate(
    'Travel to next place:',
    'Viajar al próximo lugar:',
    'Podróż do następnego miejsca:',
  );
  String get walk => _translate('Walk', 'Caminar', 'Pieszo');
  String get bike => _translate('Bike', 'Bicicleta', 'Rower');
  String get drive => _translate('Drive', 'Conducir', 'Jazda samochodem');
  String get maximumDaysReached => _translate(
    'Maximum days reached',
    'Máximo de días alcanzado',
    'Osiągnięto maksymalną liczbę dni',
  );
  String get totalDistance =>
      _translate('Total Distance:', 'Distancia Total:', 'Całkowita odległość:');
  String get totalTime =>
      _translate('Travel Time:', 'Tiempo de Viaje:', 'Czas podróży:');

  // Edit Places Screen
  String get editPlaces =>
      _translate('Edit Places', 'Editar Lugares', 'Edytuj Miejsca');
  String get placesUpdatedSuccessfully => _translate(
    'Places updated successfully',
    'Lugares actualizados exitosamente',
    'Miejsca zaktualizowane pomyślnie',
  );
  String get searchPlaceText =>
      _translate('Search place', 'Buscar lugar', 'Szukaj miejsca');
  String get addedPlaces =>
      _translate('Added Places', 'Lugares Agregados', 'Dodane miejsca');

  // Create Trip Screen
  String get tripInformation => _translate(
    'Trip Information',
    'Información del Viaje',
    'Informacje o podróży',
  );
  String get tripNameLabel =>
      _translate('Trip Name', 'Nombre del Viaje', 'Nazwa podróży');
  String get descriptionLabel =>
      _translate('Description', 'Descripción', 'Opis');
  String get selectDates =>
      _translate('Select Dates', 'Seleccionar Fechas', 'Wybierz daty');
  String get addPlaces =>
      _translate('Add Places', 'Agregar Lugares', 'Dodaj Miejsca');
  String get next => _translate('Next', 'Siguiente', 'Dalej');
  String get createTripButton =>
      _translate('Create Trip', 'Crear Viaje', 'Utwórz podróż');
  String get review => _translate('Review', 'Revisar', 'Przejrzyj');
  String get reviewYourTrip => _translate(
    'Review your trip details before creating',
    'Revisa los detalles de tu viaje antes de crear',
    'Przejrzyj szczegóły podróży przed utworzeniem',
  );

  // Place Autocomplete
  String get noPlacesFound => _translate(
    'No places found. Try a different search.',
    'No se encontraron lugares. Intenta una búsqueda diferente.',
    'Nie znaleziono miejsc. Spróbuj innego wyszukiwania.',
  );
  String get typeToSearch => _translate(
    'Type to search...',
    'Escribe para buscar...',
    'Wpisz, aby wyszukać...',
  );
  String get add => _translate('Add', 'Agregar', 'Dodaj');

  // Trip Status
  String get active => _translate('Active', 'Activo', 'Aktywny');
  String get planned => _translate('Planned', 'Planeado', 'Zaplanowany');
  String get startTrip => _translate('Start', 'Iniciar', 'Rozpoczynacie');

  // Active Trip Screen
  String get endTrip =>
      _translate('End Trip', 'Terminar Viaje', 'Zakończyć podróż');
  String get confirmEndTrip => _translate(
    'Are you sure you want to end this trip?',
    '¿Estás seguro de que deseas terminar este viaje?',
    'Czy na pewno chcesz zakończyć tę podróż?',
  );
  String get steps => _translate('Steps', 'Pasos', 'Kroki');
  String get nextPlace => _translate('Next', 'Siguiente', 'Następny');
  String get locationPermissionRequired => _translate(
    'Location permission required',
    'Permiso de ubicación requerido',
    'Wymagane pozwolenie na lokalizację',
  );

  // Logout
  String get confirmLogout => _translate(
    'Are you sure you want to logout?',
    '¿Estás seguro de que deseas cerrar sesión?',
    'Czy na pewno chcesz się wylogować?',
  );

  // Trip Stats & Schedule
  String get stats => _translate('Statistics', 'Estadísticas', 'Statystyka');
  String get distance => _translate('Distance', 'Distancia', 'Odległość');
  String get duration => _translate('Duration', 'Duración', 'Czas trwania');
  String get pace => _translate('Pace', 'Ritmo', 'Tempo');
  String get elevation => _translate('Elevation', 'Elevación', 'Elevacja');
  String get completed => _translate('Completed', 'Completado', 'Ukończone');
  String get remaining => _translate('Remaining', 'Restante', 'Pozostało');

  // Trip Detail Screen - Labels
  String get tripStats =>
      _translate('Trip Stats', 'Estadísticas del Viaje', 'Statystyka podróży');
  String get scheduleTitle => _translate(
    'Schedule Summary',
    'Resumen del Itinerario',
    'Podsumowanie harmonogramu',
  );
  String get descriptionTitle =>
      _translate('Description', 'Descripción', 'Opis');
  String get placesTitle => _translate('Places', 'Lugares', 'Miejsca');
  String get dailyScheduleTitle =>
      _translate('Daily Schedule', 'Itinerario Diario', 'Harmonogram dzienny');
  String get assignDaysToPlaces => _translate(
    'Assign Days to Places',
    'Asignar Días a Lugares',
    'Przypisz dni do miejsc',
  );
  String get tripMapTitle =>
      _translate('Trip Map', 'Mapa del Viaje', 'Mapa podróży');
  String get noPhotosYet =>
      _translate('No photos yet', 'Sin fotos aún', 'Brak zdjęć');
  String get errorLoadingPhotos => _translate(
    'Error loading photos:',
    'Error al cargar fotos:',
    'Błąd ładowania zdjęć:',
  );

  // Additional Translations - Messages & Dialogs
  String get placesUpdatedSuccessfully => _translate(
    'Places updated successfully',
    'Lugares actualizados exitosamente',
    'Miejsca zaktualizowane pomyślnie',
  );
  String get scheduleUpdatedSuccessfully => _translate(
    'Schedule updated successfully',
    'Itinerario actualizado exitosamente',
    'Harmonogram zaktualizowany pomyślnie',
  );
  String get tripDetailsTitle => _translate('Trip Details', 'Detalles del Viaje', 'Szczegóły podróży');
  String get deletePhoto => _translate('Delete Photo', 'Eliminar Foto', 'Usuń Zdjęcie');
  String get areYouSureDeletePhoto => _translate(
    'Are you sure you want to delete this photo?',
    '¿Estás seguro de que deseas eliminar esta foto?',
    'Czy na pewno chcesz usunąć to zdjęcie?',
  );
  String get photoDeleted => _translate('Photo deleted', 'Foto eliminada', 'Zdjęcie usunięte');
  String get photoUploadedSuccessfully => _translate(
    'Photo uploaded successfully!',
    '¡Foto cargada exitosamente!',
    'Zdjęcie przesłane pomyślnie!',
  );
  String get errorUploading => _translate('Error uploading:', 'Error al cargar:', 'Błąd przesyłania:');
  String get takePhoto => _translate('Take Photo', 'Tomar Foto', 'Zrób Zdjęcie');
  String get tripDates => _translate('Trip Dates', 'Fechas del Viaje', 'Daty podróży');
  String get addedPlaces => _translate('Added Places', 'Lugares Agregados', 'Dodane miejsca');
  String get pleaseFillAllFields => _translate(
    'Please fill all fields',
    'Por favor llena todos los campos',
    'Proszę wypełnić wszystkie pola',
  );
  String get pleaseEnterTripName => _translate(
    'Please enter trip name',
    'Por favor ingresa el nombre del viaje',
    'Proszę wpisz nazwę podróży',
  );
  String get pleaseSelectDates => _translate(
    'Please select dates',
    'Por favor selecciona las fechas',
    'Proszę wybierz daty',
  );
  String get endDateMustBeAfterStart => _translate(
    'End date must be after start date',
    'La fecha de finalización debe ser posterior a la fecha de inicio',
    'Data zakończenia musi być po dacie rozpoczęcia',
  );
  String get pleaseAddAtLeastOnePlace => _translate(
    'Please add at least one place',
    'Por favor agrega al menos un lugar',
    'Proszę dodaj co najmniej jedno miejsce',
  );
  String get tripCreatedSuccessfully => _translate(
    'Trip created successfully!',
    '¡Viaje creado exitosamente!',
    'Podróż stworzona pomyślnie!',
  );
  String get backButton => _translate('Back', 'Atrás', 'Wróć');
  String get createTripTitle => _translate('Create Trip', 'Crear Viaje', 'Utwórz podróż');
  String get placesYouWillVisit => _translate(
    'Places you\'ll visit:',
    'Lugares que visitarás:',
    'Miejsca które odwiedzisz:',
  );
  String get about => _translate('About', 'Acerca de', 'O aplikacji');
  String get version => _translate('Version 1.0.0', 'Versión 1.0.0', 'Wersja 1.0.0');
  String get totalDays => _translate('Total Days:', 'Días Totales:', 'Razem dni:');
  String get totalDistance => _translate('Total Distance:', 'Distancia Total:', 'Całkowita odległość:');
  String get travelTime => _translate('Travel Time:', 'Tiempo de Viaje:', 'Czas podróży:');
  String get walk => _translate('Walk', 'Caminar', 'Pieszo');
  String get bike => _translate('Bike', 'Bicicleta', 'Rower');
  String get drive => _translate('Drive', 'Conducir', 'Jazda samochodem');
  String get dash => _translate('-', '-', '-');

  // Navigation
  String get home => _translate('Home', 'Inicio', 'Strona główna');
  String get back => _translate('Back', 'Atrás', 'Wróć');

  // Buttons and Actions
  String get cancel => _translate('Cancel', 'Cancelar', 'Anuluj');
  String get confirm => _translate('Confirm', 'Confirmar', 'Potwierdź');
  String get ok => _translate('OK', 'OK', 'OK');
  String get delete => _translate('Delete', 'Eliminar', 'Usuń');

  // Error Messages
  String get error => _translate('Error: ', 'Error: ', 'Błąd: ');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'es', 'pl'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    return Future.value(AppLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
