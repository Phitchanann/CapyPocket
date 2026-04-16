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

## Backend Setup

The Node.js API lives in [backend/](backend). Use these steps to prepare it:

1. Import [database/CapyPocket.sql](database/CapyPocket.sql) into MySQL.
2. Change into [backend/](backend) and copy [.env.example](backend/.env.example) to [.env](backend/.env).
3. Update [.env](backend/.env) with your MySQL credentials and a strong `JWT_SECRET`.
4. Install dependencies with `npm install`.
5. Seed the sample account with `npm run seed`.
6. Start the server with `npm start` for production or `npm run dev` for auto-reload.

The seeded demo account is `test@example.com` / `123456`.

## Run With MySQL

1. Execute [database/CapyPocket.sql](database/CapyPocket.sql) on your MySQL server.
2. Update [./.env.example](.env.example) with your environment values.
3. Start Flutter normally:

```bash
flutter pub get
flutter run
```

The app loads DB config from `.env.example` automatically. If env file loading fails, it falls back to `--dart-define` and default values.

You can still run with explicit dart-define if needed:

```bash
flutter run \
	--dart-define=CAPY_USE_MYSQL=true \
	--dart-define=CAPY_MYSQL_HOST=127.0.0.1 \
	--dart-define=CAPY_MYSQL_PORT=3306 \
	--dart-define=CAPY_MYSQL_USER=root \
	--dart-define=CAPY_MYSQL_PASSWORD=your_password \
	--dart-define=CAPY_MYSQL_DATABASE=capypocket
```

If `CAPY_USE_MYSQL` is not set (or false), the app uses local SQLite as before.

## Database Health Check

The Home dashboard now shows a real-time database status chip:

- Mode: `MySQL` or `SQLite`
- Status: `online/offline`
- Latency: round-trip milliseconds

The status refreshes automatically every 8 seconds.

## Notes

- This project currently uses local on-device storage, which satisfies the database requirement.
- The reminder and budget pages are connected to real in-app data so the prototype can be demonstrated as a working mobile application.
