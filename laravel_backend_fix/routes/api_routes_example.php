<?php

/**
 * Copy the protected routes below into your Laravel routes/api.php.
 * Ensure these routes use the 'api.customer' middleware so $request->user() is set.
 */

use App\Http\Controllers\Api\ApiAuthController;
use Illuminate\Support\Facades\Route;

// Public routes (no auth)
Route::post('/login', [ApiAuthController::class, 'login']);
Route::post('/register', [ApiAuthController::class, 'register']);
Route::post('/verify-otp', [ApiAuthController::class, 'verifyOtp']);
Route::post('/resend-otp', [ApiAuthController::class, 'resendOtp']);
// Forgot password (public)
Route::post('/forgot-password', [ApiAuthController::class, 'forgotPassword']);
Route::post('/forgot-password/resend-otp', [ApiAuthController::class, 'resendForgotPasswordOtp']);
Route::post('/forgot-password/verify-otp', [ApiAuthController::class, 'verifyForgotPasswordOtp']);
Route::post('/forgot-password/reset-password', [ApiAuthController::class, 'resetPassword']);

// Protected routes (require Bearer token – Flutter sends Authorization: Bearer {token})
Route::middleware('api.customer')->group(function () {
    Route::post('/logout', [ApiAuthController::class, 'logout']);
    Route::get('/me', [ApiAuthController::class, 'me']);
    Route::get('/profile', [ApiAuthController::class, 'profile']);
        Route::get('/account', [ApiAuthController::class, 'account']);  // Flutter fetchAccount() calls this
        Route::post('/profile/update', [ApiAuthController::class, 'updateProfile']);
        // Change password: send OTP → verify OTP → update (current + new password, keep_logged_in)
        Route::post('/change-password/send-otp', [ApiAuthController::class, 'changePasswordSendOtp']);
        Route::post('/change-password/verify-otp', [ApiAuthController::class, 'changePasswordVerifyOtp']);
        Route::post('/change-password/resend-otp', [ApiAuthController::class, 'changePasswordResendOtp']);
        Route::post('/change-password/update', [ApiAuthController::class, 'changePasswordUpdate']);
});
