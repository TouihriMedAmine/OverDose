# Django ↔ Flutter API Connections

This document outlines all HTTP API connections between the Flutter mobile app and Django backend.

## Architecture Overview

**Connection Type**: HTTP/REST with JWT Authentication  
**Base URL**: `http://localhost:8000` (configurable per platform)  
**Authentication**: Bearer token in `Authorization` header

### Platform-Specific URLs
- Android Emulator: `http://10.0.2.2:8000`
- iOS Simulator: `http://127.0.0.1:8000`
- Windows/Desktop: `http://127.0.0.1:8000`

---

## API Endpoints

### Authentication Endpoints (`/api/auth/`)

#### 1. **Register User**
- **Method**: `POST`
- **Endpoint**: `/api/auth/register/`
- **Auth Required**: No
- **Request Body**:
  ```json
  {
    "username": "john_doe",
    "email": "john@example.com",
    "password": "password123",
    "password_confirm": "password123",
    "date_of_birth": "1990-01-15",
    "gender": "M",
    "diseases": "diabetes, hypertension"
  }
  ```
- **Response**: `201` - Logs in automatically
- **Flutter Service**: `AuthService.register()`

#### 2. **Login**
- **Method**: `POST`
- **Endpoint**: `/api/auth/login/`
- **Auth Required**: No
- **Request Body**:
  ```json
  {
    "username": "john_doe",
    "password": "password123"
  }
  ```
- **Response**: `200`
  ```json
  {
    "access": "eyJ0eXAi...",
    "refresh": "eyJ0eXAi..."
  }
  ```
- **Flutter Service**: `AuthService.login()`

#### 3. **Get Current User**
- **Method**: `GET`
- **Endpoint**: `/api/auth/me/`
- **Auth Required**: Yes (Bearer token)
- **Response**: `200`
  ```json
  {
    "id": 1,
    "username": "john_doe",
    "email": "john@example.com",
    "date_of_birth": "1990-01-15",
    "gender": "M",
    "diseases": "diabetes, hypertension"
  }
  ```
- **Flutter Service**: `AuthService.loadMe()`

#### 4. **Update Profile**
- **Method**: `PATCH`
- **Endpoint**: `/api/auth/me/`
- **Auth Required**: Yes (Bearer token)
- **Request Body**:
  ```json
  {
    "email": "newemail@example.com",
    "date_of_birth": "1990-01-15",
    "gender": "M",
    "diseases": "diabetes"
  }
  ```
- **Response**: `200` - Updated user object
- **Flutter Service**: `AuthService.updateProfile()`

#### 5. **Refresh Token**
- **Method**: `POST`
- **Endpoint**: `/api/auth/token/refresh/`
- **Auth Required**: No
- **Request Body**:
  ```json
  {
    "refresh": "eyJ0eXAi..."
  }
  ```
- **Response**: `200`
  ```json
  {
    "access": "eyJ0eXAi..."
  }
  ```
- **Flutter Client**: `ApiClient._refreshAccess()` (automatic on 401)

---

### Search API Endpoints (`/api/`)

#### 6. **Product Search** ✨ **POST**
- **Method**: `POST`
- **Endpoint**: `/api/search/`
- **Auth Required**: Yes (optional - returns loyalty ranking if authenticated)
- **Request Body**:
  ```json
  {
    "q": "insulin",
    "category": "medications",
    "fallback": true,
    "use_loyalty": true
  }
  ```
- **Response**: `200`
  ```json
  {
    "query": "insulin",
    "category": "medications",
    "summary": "Found 5 products matching...",
    "search_scope_note": "Medication category",
    "products": [
      {
        "title": "Insulin Pen Model X",
        "price": "45.00 TND",
        "toxicity_label": "low",
        "brand": "Novo Nordisk"
      }
    ],
    "search_links": [],
    "brand_loyalty": {
      "enabled": true,
      "favorite_brands": [
        {"brand": "Novo Nordisk", "score": 0.95}
      ]
    }
  }
  ```
- **Flutter Service**: `SearchService.search()`

#### 7. **Chat (LLM Q&A)** ✨ **NEW - POST**
- **Method**: `POST`
- **Endpoint**: `/api/chat/`
- **Auth Required**: No
- **Request Body**:
  ```json
  {
    "message": "Which product is safest?",
    "last_query": "insulin",
    "products": [
      {"title": "Insulin Pen", "toxicity_label": "low", "price": "45.00"}
    ]
  }
  ```
- **Response**: `200`
  ```json
  {
    "user_message": "Which product is safest?",
    "bot_response": "Based on your search...",
    "timestamp": "2026-04-26T10:30:00Z"
  }
  ```
- **Flutter Service**: `ChatService.sendMessage()`
- **Status**: Ready for LLM backend integration

#### 8. **Scan & Barcode Recognition** ✨ **NEW - POST**
- **Method**: `POST`
- **Endpoint**: `/api/scan/recognize/`
- **Auth Required**: No
- **Request Body** (multipart or base64):
  ```json
  {
    "image": "base64encodedimagestring...",
    "format": "base64"
  }
  ```
- **Response**: `200`
  ```json
  {
    "detected": true,
    "barcode_type": "EAN-13",
    "barcode_value": "5901234123457",
    "confidence": 0.95,
    "product_info": {
      "name": "Insulin Pen",
      "ean": "5901234123457",
      "description": "Product matched from barcode"
    },
    "image_processed": true
  }
  ```
- **Flutter Service**: `ScanService.recognizeBarcode()`
- **Status**: Ready for barcode/QR recognition library integration (pyzbar, OpenCV)

#### 9. **Analysis History** ✨ **NEW - GET & POST**

##### GET Search History
- **Method**: `GET`
- **Endpoint**: `/api/analysis/history/?limit=10&offset=0`
- **Auth Required**: Yes
- **Query Parameters**:
  - `limit`: Max records (1-100, default 20)
  - `offset`: Pagination offset (default 0)
- **Response**: `200`
  ```json
  {
    "total_searches": 3,
    "offset": 0,
    "limit": 10,
    "history": [
      {
        "id": 1,
        "query": "insulin pen",
        "category": "medications",
        "result_count": 5,
        "timestamp": "2026-04-26T10:30:00Z",
        "top_result": "Insulin Pen Model X"
      }
    ]
  }
  ```
- **Flutter Service**: `AnalysisService.getHistory()`

##### POST Save Search
- **Method**: `POST`
- **Endpoint**: `/api/analysis/history/`
- **Auth Required**: Yes
- **Request Body**:
  ```json
  {
    "query": "insulin",
    "category": "medications",
    "result_count": 5,
    "results_summary": [
      {"title": "Insulin Pen", "price": "45.00"}
    ]
  }
  ```
- **Response**: `200`
  ```json
  {
    "ok": true,
    "message": "Search 'insulin' saved to analysis history.",
    "query": "insulin",
    "category": "medications",
    "result_count": 5
  }
  ```
- **Flutter Service**: `AnalysisService.saveSearch()`

---

### Brand Learning Endpoints (`/api/learning/`)

#### 10. **Record Product Click**
- **Method**: `POST`
- **Endpoint**: `/api/learning/click/`
- **Auth Required**: Yes
- **Request Body**:
  ```json
  {
    "title": "Insulin Pen Model X"
  }
  ```
- **Response**: `200`
  ```json
  {
    "ok": true,
    "brand_inferred": "Novo Nordisk"
  }
  ```
- **Flutter Service**: `SearchService.recordClick()`

#### 11. **Get Favorite Brands**
- **Method**: `GET`
- **Endpoint**: `/api/learning/favorite-brands/?limit=6`
- **Auth Required**: Yes
- **Query Parameters**:
  - `limit`: Max brands (1-30, default 8)
- **Response**: `200`
  ```json
  {
    "brands": [
      {"brand": "Novo Nordisk", "score": 0.95},
      {"brand": "Eli Lilly", "score": 0.82}
    ]
  }
  ```

---

## Flutter Services Architecture

### 1. **ApiClient** (`lib/services/api_client.dart`)
- Core HTTP client with JWT auth
- Methods: `get()`, `post()`, `patch()`
- Auto-refreshes expired tokens on 401
- Base URL: `AppConfig.apiBaseUrl`

### 2. **AuthService** (`lib/services/auth_service.dart`)
- User registration, login, profile management
- Methods: `login()`, `register()`, `loadMe()`, `updateProfile()`

### 3. **SearchService** (`lib/services/search_service.dart`)
- Product search and click tracking
- Methods: `search()`, `recordClick()`

### 4. **ChatService** (`lib/services/chat_service.dart`) ✨ NEW
- LLM-based Q&A chat
- Methods: `sendMessage()`
- Integrates search context into messages

### 5. **ScanService** (`lib/services/scan_service.dart`) ✨ NEW
- Barcode/QR code recognition
- Methods: `recognizeBarcode()`
- Takes image bytes and returns barcode data

### 6. **AnalysisService** (`lib/services/analysis_service.dart`) ✨ NEW
- Search history and analysis
- Methods: `getHistory()`, `saveSearch()`

---

## Flutter Widgets Using APIs

| Widget | Services Used | API Calls |
|--------|---------------|-----------|
| **Login** | AuthService | `POST /api/auth/login/` |
| **Register** | AuthService | `POST /api/auth/register/` |
| **Profile Tab** | AuthService | `GET /api/auth/me/`, `PATCH /api/auth/me/` |
| **Home Tab** | SearchService | `POST /api/search/`, `POST /api/learning/click/` |
| **Chat Bot Tab** ✨ | ChatService | `POST /api/chat/` |
| **Scan Tab** ✨ | ScanService | `POST /api/scan/recognize/` |
| **Analysis Tab** ✨ | AnalysisService | `GET /api/analysis/history/`, `POST /api/analysis/history/` |

---

## Request/Response Flow Example

### Example: User Search → Chat → Save Analysis

```
1. User searches for "insulin" on Home tab
   ↓
   SearchService.search(q="insulin")
   → POST /api/search/
   ← Returns 10 products + toxicity labels

2. User asks chat bot question
   ↓
   ChatService.sendMessage(message="which is safest?")
   → POST /api/chat/ with product context
   ← Returns LLM-generated answer

3. Tab switches to Analysis
   ↓
   AnalysisService.getHistory()
   → GET /api/analysis/history/
   ← Returns past 10 searches

4. (Optional) Save current search
   ↓
   AnalysisService.saveSearch(query="insulin", result_count=10)
   → POST /api/analysis/history/
   ← Confirms save
```

---

## Error Handling

All Flutter services include:
- **401 Unauthorized**: Auto-refresh token via `ApiClient._refreshAccess()`
- **Network errors**: Thrown as exceptions with descriptive messages
- **API errors**: Parsed from JSON response `error` field
- **Loading states**: UI shows progress indicators during async calls

---

## Next Steps for Full Integration

### Backend (Django)
- [ ] Wire LLM backend to `/api/chat/` (GPT, Claude, Ollama, etc.)
- [ ] Integrate barcode recognition to `/api/scan/recognize/` (pyzbar, OpenCV)
- [ ] Implement database models for `SearchHistory` to back `/api/analysis/history/`
- [ ] Add rate limiting and caching for high-traffic endpoints

### Frontend (Flutter)
- [ ] Add error/retry UI for failed API calls
- [ ] Implement offline caching of search results
- [ ] Add image picker for scan tab (currently takes camera photos)
- [ ] Show loading skeletons during data fetches

---

## Testing Endpoints

### cURL Examples

```bash
# Register
curl -X POST http://localhost:8000/api/auth/register/ \
  -H "Content-Type: application/json" \
  -d '{"username":"test","email":"test@example.com","password":"pass123","password_confirm":"pass123"}'

# Search
curl -X POST http://localhost:8000/api/search/ \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"q":"insulin","category":"medications","fallback":true,"use_loyalty":true}'

# Chat
curl -X POST http://localhost:8000/api/chat/ \
  -H "Content-Type: application/json" \
  -d '{"message":"Is this safe?","last_query":"insulin","products":[]}'

# Get Analysis History
curl -X GET "http://localhost:8000/api/analysis/history/?limit=10" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

---

## Status Summary

✅ **Fully Connected**: Auth, Search, Brand Learning  
✨ **Ready to Extend**: Chat, Scan, Analysis (API endpoints created, services wired, ready for backend logic)  
🔄 **In Development**: LLM integration, barcode recognition, database persistence  

All POST and GET connections are established and working!
