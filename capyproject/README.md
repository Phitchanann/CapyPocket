# CapyPocket

CapyPocket is a cute finance and wallet mobile application built with Flutter for the course project Phase 2.

## Phase 2 Checklist

- 9+ application screens implemented
- Local database integration with SQLite using `sqflite`
- Advanced mobile feature using the accelerometer with `sensors_plus`
- Reusable UI kit and consistent mobile-first layout

## Main Screens

- Home dashboard
- Money room
- Savings goals
- Profile
- Quick add
- Add transaction
- Edit transaction
- Monthly snapshot
- Insight analysis
- Budget setup
- Category management
- Add category
- Reminder settings
- App settings

Login and create account screens are also included, but they are separate from the counted core app pages.

## Data Layer

The app stores the following data locally on the device:

- Transactions
- Categories
- Savings goals

Database files are managed through `lib/data/capy_database.dart` and shared state is coordinated through `lib/state/capy_app_store.dart`.

## Advanced Feature

CapyPocket supports shake-to-quick-add using the device accelerometer. When the user shakes the phone on the main app flow, a quick-add sheet opens for fast transaction entry.

## Run

```bash
flutter pub get
flutter run
```

## Notes

- This project currently uses local on-device storage, which satisfies the database requirement.
- The reminder and budget pages are connected to real in-app data so the prototype can be demonstrated as a working mobile application.
