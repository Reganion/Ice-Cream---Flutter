# Laravel backend fix – "Not authenticated" on profile/account

After login, the Flutter app calls **GET /api/v1/account** with `Authorization: Bearer {token}`. The backend returns "Not authenticated" when `$request->user()` is null. That happens when the **middleware does not set the user** on the request from the token.

## 1. Middleware: set user from token

Copy the middleware file into your Laravel project:

- **From:** `laravel_backend_fix/App/Http/Middleware/AuthenticateApiCustomer.php`
- **To:** `app/Http/Middleware/AuthenticateApiCustomer.php` (in your Laravel project)

This middleware:

- Reads the token from `Authorization: Bearer {token}` or `X-Session-Token`.
- Looks up `Cache::get(CACHE_PREFIX . $token)` to get the customer id (same as in your login).
- Loads `Customer::find($customerId)` and sets it on the request with `$request->setUserResolver(fn () => $customer)` so `$request->user()` in your controllers returns the Customer.

**Cache key:** The middleware uses `CACHE_PREFIX = 'api_customer_token:'`. Your login must use the same prefix when storing the token, e.g.:

```php
Cache::put(AuthenticateApiCustomer::CACHE_PREFIX . $token, $customer->id, now()->addMinutes(AuthenticateApiCustomer::TTL_MINUTES));
```

If your current login uses a different prefix, either change the middleware’s `CACHE_PREFIX` to match, or change the login to use `AuthenticateApiCustomer::CACHE_PREFIX`.

## 2. Routes: protect account/profile with `api.customer`

In `routes/api.php` (with your `Route::prefix('v1')` or similar), ensure the account and profile routes use the `api.customer` middleware:

```php
Route::middleware('api.customer')->group(function () {
    Route::get('/account', [ApiAuthController::class, 'account']);
    Route::get('/profile', [ApiAuthController::class, 'profile']);
    Route::get('/me', [ApiAuthController::class, 'me']);
    Route::post('/logout', [ApiAuthController::class, 'logout']);
    Route::post('/profile/update', [ApiAuthController::class, 'updateProfile']);
});
```

See `routes/api_routes_example.php` for a full example.

## 3. Bootstrap: register middleware alias (you already have this)

In `bootstrap/app.php` (Laravel 11) you already have:

```php
$middleware->alias([
    'api.customer' => \App\Http\Middleware\AuthenticateApiCustomer::class,
]);
```

No change needed if this is already there.

## 4. Login response (already correct)

Your login already returns:

```json
{
  "success": true,
  "message": "Logged in successfully.",
  "customer": { ... },
  "token": "..."
}
```

The Flutter app reads `token` and sends it as `Authorization: Bearer {token}` on GET /api/v1/account. Once the middleware above is in place and the routes use `api.customer`, `$request->user()` will be set and "Not authenticated" will be fixed.
