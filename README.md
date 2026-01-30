# <img src="./assets/tripbud_logo.svg" alt="TripBud Logo" width="100"/> TripBud - Final Documentation

## Project Description

**TripBud** is a cross-platform Flutter application for planning, organizing, and tracking multi-day trips. Features include Firebase authentication, real-time GPS tracking with triple-mode distance monitoring (walking/driving/biking), pedometer integration, photo galleries, trip statistics, and offline-first data persistence with Hive. Material Design 3 compliant with support for 3 languages (English, Spanish, Polish).

## Integrations

**Authentication & User Management**

- Firebase Email/Password & Google Sign-in and Log-in
- Password reset, user profile, language preferences, user's height for pedometer calculation

**Trip Tracking & Distance Monitoring**

- Multi-day itinerary planning with days-at-place scheduling
- Real-time GPS tracking with speed-based categorization
- Triple-mode distance: Walked (GPS < 20 km/h), Driven (> 20 km/h), Biked (toggle mode)
- Pedometer integration for step counting with height-based stride calculation

**Data Management**

- Cloud Firestore for real-time sync
- Hive offline-first local database
- Local photo storage
- Google Places API integration with autocomplete suggestions

**UI/UX**

- Material Design 3 with custom animations (fade/slide/scale transitions)
- Interactive Google Maps with polyline routes
- Multi-tab interface (Schedule, Map, Gallery)

---

## Technology Stack

| Category             | Technology                                                                                                      |
| -------------------- | --------------------------------------------------------------------------------------------------------------- |
| **Framework**        | Flutter 3.9.2+, Dart 3.9.2+                                                                                     |
| **Backend**          | Firebase Auth 4.10.0, Cloud Firestore 4.12.0, Google Sign-In 6.0.0                                              |
| **Mapping**          | Google Maps API 2.4.0, Geolocator 11.0.0, Pedometer 4.1.1                                                       |
| **Local Storage**    | Hive 2.2.3, Path Provider 2.1.2                                                                                 |
| **State Management** | Provider 6.0.0                                                                                                  |
| **Other**            | Image Picker 1.0.4, Table Calendar 3.0.8, intl 0.20.2, Permission Handler 11.0.0, Flutter Launcher Icons 0.13.1 |

---

## Required project assumptions

| Requirement         | Status                                                        |
| ------------------- | ------------------------------------------------------------- |
| **Code Quality**    | 0 analyzer errors/warnings, 100% null-safe                    |
| **Custom Widgets**  | PlaceAutocomplete, DateRangePicker, PlaceMap, GalleryGridView |
| **Material Design** | Full Material Design 3 compliance                             |

## Optional Requirements

| Requirement                         | Status                                                    |
| ----------------------------------- | --------------------------------------------------------- |
| **Platform Support**                | Android, Web                                              |
| **Animations**                      | Custom fade/slide/scale transitions (AnimationController) |
| **Firebase Auth**                   | Email/password & Google OAuth fully implemented           |
| **Multi-step form with validation** | Trip creation                                             |
| **Platform Channels**               | Using pub packages (image_picker, geolocator, pedometer)  |
| **Internationalization**            | 3 languages (English, Polish, Spanish)                    |
| **Local Data Persistence**          | Hive offline database with auto-sync to Firestore         |

---

## Instructions for Quick Start

### Prerequisites

- Flutter 3.9.2+, Dart 3.9.2+
- Firebase project credentials
- Google Maps API key

### Setup

```bash
# 1. Install dependencies
flutter pub get

# 2. Update lib/firebase_options.dart with Firebase credentials

# 3. Add Google Maps API key to:
#    - android/app/src/main/AndroidManifest.xml
#    - ios/Runner/Info.plist

# 4. Run
flutter run                    # Mobile/Web
```

### Build for app file

```bash
flutter build apk              # Android
flutter build web              # Web
```

---

## Test Account

**Email:** demo@example.com  
**Password:** password123

---

## Firestore Schema

```
users/{userId}
├── email, displayName, photoUrl, languageCode, createdAt, updatedAt

trips/{tripId}
├── userId, name, description, startDate, endDate, isActive, isPaused
├── countries[], createdAt, updatedAt
├── stats: {totalDistance, distanceWalked, distanceDriven, distanceBiked,
│           totalSteps, totalDuration, photosCount}
└── places/{placeId}: {name, latitude, longitude, placeId, order}

schedule/{tripId}/{dateISO}
├── dayNumber, date, distanceCovered, stepsTaken, photoIds[]
└── schedule/{id}: {placeId, scheduledTime, estimatedDuration,
                    visited, actualArrivalTime, transportationMode}

storage/trips/{userId}/{tripId}/photos/{photoId}
```

---

## Local Storage (Hive)

```
Box 'trips': List<HiveTrip>
├── id, title, description, startDate, endDate
├── places: List<HivePlace>, lastModified, totalDistance

Box 'user_preferences'
├── height (cm), languageCode
```

---

## Architecture

- **Service Pattern** - Abstract services (Auth, TripData, LocationTracking)
- **Provider** - Global state management & DI
- **Repository Pattern** - TripRepository for local/cloud sync
- **Clean Code** - Separation of concerns, SOLID principles
- **Code Quality** - 0 errors, 0 warnings, 100% null-safe

**Structure:**

```
lib/
├── screens/ (9 main screens with features)
├── services/ (8 business logic services)
├── widgets/ (4 custom interactive widgets)
├── models/ (Trip, Place, User, HiveModels)
├── l10n/ (3-language localization)
└── constants/ (API keys, configuration)
```

---

## Key Implementation Details

**Distance Tracking Algorithm:**

- Pedometer: `distance_km = (steps × (height_cm × 0.43 / 100)) / 100000`
- GPS: `speed_kmh = position.speed × 3.6`
  - If biking: add to `distanceBiked`
  - Else if speed > 20: add to `distanceDriven`
  - Else: add to `distanceWalked`

**Optimizations:**

Lazy loading, local caching, debounced search (500ms), GPS filtering (10m)

**Data Persistence:**

- Automatic save on PopScope callback (back button)
- Save on screen exit via `_saveCurrentProgress()`
- Save on widget dispose
- Updates Firestore via `updateTrip()`

**Permissions (Android):**

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACTIVITY_RECOGNITION" />
```

---
