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

## Customer authentication

The customer app starts with a mobile-number and OTP sign-in flow before opening the shopping experience. The current UI uses a deterministic demo OTP, `123456`, so the mobile flow can be tested without storing credentials or secrets. The authentication boundary can be connected to the production customer identity API in a later integration batch.

## Customer address management

The authenticated customer can open **My Addresses** from Profile to add, edit, and delete saved delivery addresses. The current implementation keeps the address book in the mobile session; the production Address APIs can replace this local state in a later backend integration batch.

## Customer cart persistence

The authenticated customer cart is persisted locally per mobile number, so cart items survive app restarts. Signing out clears that customer's local cart. This is local device persistence; production order/cart synchronization remains part of the planned backend integration.

## Product details

Customers can tap any product card to open a product details screen, review the unit price, choose a quantity, and add the selected quantity to the cart in one action.
