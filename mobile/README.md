# Tunisia Product Search — Flutter (Dart)

Mobile client for the Django API (`backend/`): login, register (with health checkboxes from `assets/health_conditions.json`), and product search.

## Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (includes Dart)
- Django API running (e.g. `python manage.py runserver 0.0.0.0:8000` from `backend/`)

## Generate Android / iOS / Web platform folders

From the repo root, if `mobile/` has no `android/` or `ios/` yet:

```bash
cd mobile
flutter create .
```

This adds platform projects without removing your `lib/` code.

## API URL

| Target | Default base URL |
|--------|------------------|
| Android emulator | `http://10.0.2.2:8000` |
| iOS simulator | `http://127.0.0.1:8000` |
| Physical device | Use your PC LAN IP, e.g. `http://192.168.1.10:8000` |

Override at build/run time:

```bash
flutter run --dart-define=API_BASE=http://192.168.1.10:8000
```

## Run

```bash
cd mobile
flutter pub get
flutter run
```

Start the backend so registration and search work.

## Backend notes

- `ALLOWED_HOSTS` in `backend/core/settings.py` includes `10.0.2.2` and `*` in `DEBUG` for emulator/device access.
- For **Android** HTTP (cleartext), ensure `android:usesCleartextTraffic="true"` in debug (often added by `flutter create` for dev).

## Project layout

- `lib/main.dart` — app shell, auth routing
- `lib/config/app_config.dart` — API base URL
- `lib/services/` — `api_client`, `auth_service`, `search_service`, `token_storage`
- `lib/screens/` — login, register, home (search + profile)
