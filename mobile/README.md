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

No API secrets are stored in the mobile application. When a customer session has a token, the mobile product API sends it as a Bearer token in the Authorization header. A `401 Unauthorized` response is treated as an expired session and signs the customer out.

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

The authenticated customer can open **My Addresses** from Profile to add, edit, and delete saved delivery addresses. The current implementation keeps the address book in local mobile storage. An injectable HTTP Address API repository is now defined for the production integration. It uses `GET/POST /customers/me/addresses` and `PUT/DELETE /customers/me/addresses/{id}` with the customer Bearer token. The UI remains on local storage until those backend endpoints are deployed and the server-side address identifier is available.\n\n## Customer order API\n\nAn injectable HTTP order repository is now defined for production integration. It supports `POST /customers/me/orders` for authenticated order creation and `GET /customers/me/orders` for customer order history, using the customer Bearer token. The current checkout and order history UI remains local until the backend endpoints are deployed and server-side order IDs are available. A `401 Unauthorized` response is mapped to `OrderApiException('AUTH_UNAUTHORIZED')` so the app can reuse the existing session-expiry handling when the repository is wired into the UI.


## Customer cart API

An injectable HTTP cart repository is now defined for production integration. It supports:
- `GET /customers/me/cart` to load the authenticated customer's server-side cart
- `PUT /customers/me/cart` to replace the server-side cart contents
- `DELETE /customers/me/cart` to clear the server-side cart
- Bearer JWT authentication on every request when a session token is available
- `401 Unauthorized` mapped to `CartApiException('AUTH_UNAUTHORIZED')`

The current checkout/cart UI remains local until the backend cart endpoints are deployed and server-side inventory/pricing rules are ready. The API boundary intentionally does not switch the UI to remote cart synchronization yet.

## Customer cart persistence

The authenticated customer cart is persisted locally per mobile number, so cart items survive app restarts. Signing out clears that customer's local cart. This remains the active UI storage until server-side cart synchronization is enabled.

## Product details

Customers can tap any product card to open a product details screen, review the unit price, choose a quantity, and add the selected quantity to the cart in one action.

## Order details

Completed mobile orders retain an item snapshot locally. Customers can open an order from **My Orders** to review each item, quantity, unit price, order total, payment method, delivery address, and the existing tracking view.

## Favorites

Customers can save products to **My Favorites** from the product cards. Favorites are stored locally per customer mobile number, survive app restarts, and are cleared when that customer signs out.
