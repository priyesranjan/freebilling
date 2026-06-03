# ERP Bill - Comprehensive Project Documentation

## 🚀 Overview
ERP Bill is a robust, India-scale billing and inventory management system built with **Flutter** for the frontend and **Node.js/Express** for the backend. It is designed to empower small to medium-sized businesses with tools for billing, party management (Khata), and real-time inventory tracking.

---

## 🛠️ Recent Major Fixes & Critical Updates (April 2026)

### 1. Authentication System Stabilization
**Problem**: The introduction of a "Login with Password" feature caused significant regressions in the registration flow, leading to 404 errors and broken state management.
**Solution**: 
- **Reverted to OTP-only Auth**: The "Login with Password" UI and logic have been completely removed to restore the highly stable OTP-based authentication.
- **Simplified `AuthScreen`**: The UI has been cleaned up, removing complex toggles and redundant controllers.
- **Auto-Registration**: The system now automatically creates a business profile upon successful OTP verification if the user is not already in the database.
- **Backend Refactor**: Removed the `express.Router` for `/api` which was causing path-matching issues in production environments (like Coolify). All API endpoints are now directly defined on the `app` instance with explicit `/api` prefixes.

### 2. Backend Architecture Improvements
- **Direct Routing**: All endpoints (e.g., `/api/send-otp`, `/api/products`, `/api/khata`) are now explicitly defined to ensure 100% reliability across different hosting proxies.
- **Enhanced Logging**: A global middleware now logs every incoming request with the prefix `[REQUEST]`, allowing for real-time monitoring of traffic in server logs.
- **Versioned Health Checks**: Added `/api/health` and `/health` endpoints (current version `1.4.0`) that include a timestamp to verify successful deployments.
- **Database Schema**: Added a `password` column to the `businesses` table to support future features without breaking existing queries, but made it nullable to support OTP-only users.

### 3. Frontend Service Layer
- **Unified `ApiService`**: The `ApiService.dart` has been streamlined to match the backend's direct routing.
- **Robust Error Handling**: Improved error reporting in the app to help identify if a problem is client-side or server-side.

---

## 🏗️ Technical Stack
- **Frontend**: Flutter (3.x)
- **Backend**: Node.js, Express.js
- **Database**: PostgreSQL
- **Real-time**: Socket.io for live inventory/billing sync
- **Auth**: 2Factor.in for OTP (SMS/Voice), JWT for session management
- **Storage**: Local filesystem (uploads/logos)

---

## 🚦 Getting Started

### Backend Setup
1. Navigate to the `backend` folder.
2. Install dependencies: `npm install`
3. Configure `.env` with `DATABASE_URL`, `JWT_SECRET`, and `TWO_FACTOR_API_KEY`.
4. Start the server: `node server.js`
5. Verify: Visit `http://localhost:3000/api/health`

### Frontend Setup
1. Install Flutter dependencies: `flutter pub get`
2. Run the app: `flutter run`
3. For production build: `flutter build apk --release`

---

## 📝 Developer Notes for AI & Contributors
- **Avoid Routers**: Do not use `express.Router()` for top-level API paths as it has caused 404 issues in the current production environment.
- **Keep it Simple**: The authentication flow must remain OTP-centric unless a robust multi-factor system is requested.
- **Logging**: Always use the `[REQUEST]` or `[API LOG]` prefixes when adding new server-side logging.
- **State Management**: Ensure `ApiService.setToken` is called upon successful login to persist the session.

---

## 🛠️ Post-Mortem: Common Issues & Solutions

### 1. "404 Not Found" on API Endpoints
*   **Problem**: Using `express.Router()` caused the server to return `Cannot POST /api/...` even when the path looked correct.
*   **Solution**: Avoid nested Routers for top-level API paths. Define routes directly on the `app` instance: `app.post('/api/endpoint', ...)`.
*   **Check**: Always verify with a `GET /api/health` call.

### 2. Registration/Login Failures after Database Changes
*   **Problem**: Adding a `NOT NULL` column (like `password`) caused OTP-based registration to fail because the OTP flow doesn't provide a password immediately.
*   **Solution**: Ensure new columns in the `businesses` table are either nullable or have a default value.
*   **Command**: `ALTER TABLE businesses ALTER COLUMN password DROP NOT NULL;`

### 3. "Still the same" after Deployment
*   **Problem**: The cloud environment (Coolify) might still be serving the old container, or the build failed silently.
*   **Solution**: Check the `/api/health` endpoint. If the `version` or `timestamp` hasn't changed, the deployment didn't go through.
*   **Fix**: Trigger a "Force Redeploy" or "Clear Cache" in your hosting dashboard.

### 4. Auth State Confusion
*   **Problem**: Mixing Password and OTP login modes makes the `AuthScreen` state hard to manage.
*   **Solution**: Stick to a single primary auth method (OTP is recommended for mobile). If adding a second method, keep the logic strictly separated to avoid sending wrong parameters.
