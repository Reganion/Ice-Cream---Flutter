<?php

namespace App\Http\Middleware;

use App\Models\Customer;
use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use Symfony\Component\HttpFoundation\Response;

/**
 * Authenticates API requests using Bearer token (or X-Session-Token).
 * Token is stored in cache by ApiAuthController::login() as: CACHE_PREFIX . $token => customer_id.
 * Sets the Customer on the request so $request->user() returns the customer in account(), profile(), etc.
 */
class AuthenticateApiCustomer
{
    public const CACHE_PREFIX = 'api_customer_token:';
    public const TTL_MINUTES = 60 * 24 * 7; // 7 days

    public function handle(Request $request, Closure $next): Response
    {
        $token = $this->getTokenFromRequest($request);

        if (!$token) {
            return response()->json([
                'success' => false,
                'message' => 'Not authenticated.',
            ], 401);
        }

        $customerId = Cache::get(self::CACHE_PREFIX . $token);

        if ($customerId === null) {
            return response()->json([
                'success' => false,
                'message' => 'Not authenticated.',
            ], 401);
        }

        $customer = Customer::find($customerId);

        if (!$customer) {
            Cache::forget(self::CACHE_PREFIX . $token);
            return response()->json([
                'success' => false,
                'message' => 'Not authenticated.',
            ], 401);
        }

        // So $request->user() in controllers returns the Customer
        $request->setUserResolver(fn () => $customer);

        return $next($request);
    }

    private function getTokenFromRequest(Request $request): ?string
    {
        $header = $request->header('Authorization');
        if ($header && preg_match('/^Bearer\s+(.+)$/i', $header, $m)) {
            return trim($m[1]);
        }
        return $request->header('X-Session-Token') ?: null;
    }
}
