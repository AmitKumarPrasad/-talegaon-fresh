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

The customer app uses an injectable authentication repository for the mobile-number and OTP sign-in flow.

- Demo mode remains the default for local/widget testing and uses OTP `123456`.
- Remote mode uses `POST /auth/request-otp` and `POST /auth/verify-otp`.
- Remote authentication expects a JSON response containing `token` and may return `phone` and `name`.
- Configure the backend base URL with `AUTH_BASE_URL`.
- Enable remote authentication with `AUTH_MODE=remote`.

Example:

```bash
flutter run \
  --dart-define=AUTH_MODE=remote \
  --dart-define=AUTH_BASE_URL=https://your-api.example.com
```

No OTPs, API keys, or JWT secrets are stored in the mobile application. The authenticated customer token is persisted locally for session restoration and removed on sign out. The deployed backend must implement the documented authentication endpoints before remote mode is enabled for production.

## Customer address management

The authenticated customer can open **My Addresses** from Profile to add, edit, and delete saved delivery addresses. The current implementation keeps the address book in the mobile session; the production Address APIs can replace this local state in a later backend integration batch.

## Customer cart persistence

The authenticated customer cart is persisted locally per mobile number, so cart items survive app restarts. Signing out clears that customer's local cart. This is local device persistence; production order/cart synchronization remains part of the planned backend integration.

## Product details

Customers can tap any product card to open a product details screen, review the unit price, choose a quantity, and add the selected quantity to the cart in one action.

## Order details

Completed mobile orders retain an item snapshot locally. Customers can open an order from **My Orders** to review each item, quantity, unit price, order total, payment method, delivery address, and the existing tracking view.

## Favorites

Customers can save products to **My Favorites** from the product cards. Favorites are stored locally per customer mobile number, survive app restarts, and are cleared when that customer signs out.
