# Talegaon Fresh Flutter Customer App

## Architecture

Flutter Customer App
  -> Home / Products / Product Details
  -> Cart / Checkout
  -> UPI / COD
  -> Order Confirmation / Tracking
  -> My Orders / Profile
  -> FastAPI Backend
  -> PostgreSQL
  -> Razorpay

WhatsApp remains an optional channel and is not required for the mobile app.

## Planned API integration

- Product catalog -> GET /products
- Customer identity
- Cart and order creation
- Address APIs
- Razorpay payment flow
- Order tracking/status
- Loading/error/empty states

No secrets are stored in the mobile application.

## Product API configuration

The app reads the customer catalogue from `GET /products`.

By default it uses the deployed Talegaon Fresh backend:
`https://talegaon-fresh-ai-backend.onrender.com`

For another environment, pass the API base URL without a trailing slash:

```bash
flutter run --dart-define=API_BASE_URL=https://your-api.example.com
```

No API secrets are stored in the mobile application.

## Local development

cd mobile
flutter pub get
flutter run

flutter test
