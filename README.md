# SafeVoice — GBV Reporting & Case Management Platform

A Gender-Based Violence reporting ecosystem for Ethiopia.

## Project Structure

```
safevoice_app/          Flutter mobile app (victim-facing)
safevoice_backend/      ASP.NET Core Web API (backend services)
safevoice_ai/           Python FastAPI AI service
```

---

## Quick Start

### 1. PostgreSQL
```bash
# Start PostgreSQL and create database
psql -U postgres -c "CREATE DATABASE safevoice;"
```

### 2. Backend (ASP.NET Core)
```bash
cd safevoice_backend

# Restore and build
dotnet restore
dotnet build

# Apply migrations
dotnet ef migrations add InitialCreate --project SafeVoice.Infrastructure --startup-project SafeVoice.API
dotnet ef database update --project SafeVoice.Infrastructure --startup-project SafeVoice.API

# Run API (default: https://localhost:7001)
dotnet run --project SafeVoice.API
```

Update `safevoice_backend/SafeVoice.API/appsettings.json` with your DB credentials and a strong JWT key.

### 3. AI Service (Python FastAPI)
```bash
cd safevoice_ai

pip install -r requirements.txt

# Run (default: http://localhost:8000)
uvicorn main:app --reload
```

### 4. Flutter App
```bash
cd safevoice_app

# Install dependencies
flutter pub get

# Generate localization files
flutter gen-l10n

# Run on connected device / emulator
flutter run
```

---

## Running Tests

### Flutter tests
```bash
cd safevoice_app
flutter test
```

### .NET tests
```bash
cd safevoice_backend
dotnet test
```

### Python tests (includes property-based tests with Hypothesis)
```bash
cd safevoice_ai
pytest tests/ -v
```

---

## Environment Configuration

| Variable | Description | Default |
|---|---|---|
| `API_BASE_URL` | Backend API URL (Flutter) | `https://api.safevoice.et` |
| `Jwt:Key` | JWT signing key (32+ chars) | — |
| `ConnectionStrings:DefaultConnection` | PostgreSQL connection | — |
| `AiService:BaseUrl` | Python AI service URL | `http://localhost:8000` |

---

## Architecture

- Flutter (Clean Architecture + BLoC)
- ASP.NET Core Web API with JWT + RBAC
- PostgreSQL via Entity Framework Core
- Python FastAPI AI service
- Firebase Cloud Messaging (push notifications)
- Azure Blob Storage / AWS S3 (evidence files)

---

## Security

- All traffic over HTTPS / TLS 1.2+
- AES-256-GCM on-device file encryption before upload
- AES-256 encrypted local SQLite (SQLCipher)
- JWT (15min) + Refresh Token (7 days)
- Brute-force lockout: 5 attempts → 30min lock
- Safe delete: evidence files overwritten + deleted after upload
- Audit log on all sensitive events
- Screen masking when app goes to background

---

## Status

Mobile app: **complete** (Flutter)  
Backend API: **complete** (ASP.NET Core)  
AI service: **complete** (Python FastAPI, stub models)  
Police Portal: **next phase**
