# Flutter-Django API Overview

API-wise, this app is a Flutter client that talks to Django over JSON HTTP, with JWT auth in between.

## Big Picture

1. Flutter picks a base URL from mobile/lib/config/app_config.dart.
2. Calls go through mobile/lib/services/api_client.dart, which adds Authorization: Bearer <token> when available.
3. If a protected endpoint returns 401, ApiClient automatically calls token refresh and retries once.
4. Django routes are mounted in backend/core/urls.py and split into auth, learning, and search/chat/scan/analysis APIs.

## Auth Flow

1. Login screen sends POST /api/auth/login/ with username/password from mobile/lib/services/auth_service.dart.
2. Django returns access + refresh tokens.
3. Tokens are stored locally, then used by ApiClient for protected requests.
4. Profile uses GET/PATCH /api/auth/me/ via AuthService.

## Main Feature APIs

### 1. Search tab
- POST /api/search/
- Called by mobile/lib/services/search_service.dart
- Sends q, category, fallback, use_loyalty
- Returns summary, products, toxicity labels, links, loyalty metadata

### 2. Brand learning
- POST /api/learning/click/
- Called when user clicks product results (record preference signal)

### 3. Chat tab
- POST /api/chat/
- Called by mobile/lib/services/chat_service.dart
- Sends message + last_query + products context
- Returns bot_response

### 4. Scan tab
- POST /api/scan/recognize/
- Called by mobile/lib/services/scan_service.dart
- Sends captured image as base64
- Returns barcode_type, barcode_value, confidence, product info

### 5. Analysis tab
- GET /api/analysis/history/?limit=&offset=
- POST /api/analysis/history/
- Called by mobile/lib/services/analysis_service.dart

## Backend Endpoint Map

All of these are declared in backend/search_api/urls.py:
1. /api/search/
2. /api/chat/
3. /api/scan/recognize/
4. /api/analysis/history/

## Important for real phone testing

On Android physical device, default 10.0.2.2 is emulator-only. Build/run with API_BASE set to your PC LAN IP (example 192.168.1.25), otherwise login calls will fail to connect.
