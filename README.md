# ERP Bill

Flutter app for Admin + Business Owner billing operations.

## Current Features

- Admin lifecycle controls for businesses.
- Business owner billing with product scan flow.
- Owner phone login with OTP (2factor-ready service).
- Plan management UI (Free, Basic, Premium).

## Run Locally

Install dependencies:

```bash
flutter pub get
```

Run in browser:

```bash
flutter run -d chrome
```

Run with 2factor compile-time config (demo direct mode):

```bash
flutter run -d chrome \
	--dart-define=TWO_FACTOR_API_KEY=your_key \
	--dart-define=TWO_FACTOR_TEMPLATE=your_template_name
```

If TWO_FACTOR_API_KEY is not provided, app uses local mock OTP mode.

## Production Note

Keep 2factor API key on backend only for production.
Client should call your backend auth endpoints, and backend should call 2factor.

## Architecture Guide

Full India-scale stack and Cloudflare R2 plan:

- [docs/india-scale-stack.md](docs/india-scale-stack.md)
