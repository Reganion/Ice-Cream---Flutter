<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Middleware\AuthenticateApiCustomer;
use App\Mail\OtpVerificationMail;
use App\Models\AdminNotification;
use App\Models\Customer;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Str;
use Illuminate\Validation\ValidationException;

class ApiAuthController extends Controller
{
    /**
     * Customer login (for Flutter). Starts session: creates token, stores in cache, returns token + customer.
     * Client sends token as Authorization: Bearer {token} or X-Session-Token on protected routes.
     */
    public function login(Request $request): JsonResponse
    {
        $request->validate([
            'email' => 'required|email',
            'password' => 'required',
        ]);

        $customer = Customer::where('email', $request->email)->first();

        if (!$customer || !Hash::check($request->password, $customer->password)) {
            throw ValidationException::withMessages(['email' => ['The provided credentials are incorrect.']]);
        }

        if (!$customer->isVerified()) {
            return response()->json([
                'success' => false,
                'message' => 'Please verify your email with the 4-digit OTP first.',
                'email' => $customer->email,
            ], 403);
        }

        $token = Str::random(64);
        Cache::put(AuthenticateApiCustomer::CACHE_PREFIX . $token, $customer->id, now()->addMinutes(AuthenticateApiCustomer::TTL_MINUTES));

        return response()->json([
            'success' => true,
            'message' => 'Logged in successfully.',
            'customer' => $this->customerProfileArray($customer),
            'token' => $token,
        ]);
    }

    /**
     * Customer register (for Flutter). Sends OTP to email; verify via verify-otp before login.
     */
    public function register(Request $request): JsonResponse
    {
        $request->validate([
            'firstname' => 'required|string|max:50',
            'lastname' => 'required|string|max:50',
            'email' => 'required|email|max:100|unique:customers,email',
            'contact_no' => 'nullable|string|max:20',
            'password' => 'required|string|confirmed|min:6',
        ]);

        $otp = str_pad((string) random_int(0, 9999), 4, '0', STR_PAD_LEFT);
        $otpExpiresAt = now()->addMinutes(10);

        $customer = Customer::create([
            'firstname' => $request->firstname,
            'lastname' => $request->lastname,
            'email' => $request->email,
            'contact_no' => $request->contact_no,
            'image' => 'img/default-user.png',
            'status' => Customer::STATUS_ACTIVE,
            'password' => Hash::make($request->password),
            'otp' => $otp,
            'otp_expires_at' => $otpExpiresAt,
        ]);

        try {
            Mail::to($customer->email)->send(new OtpVerificationMail($otp, $customer->email));
        } catch (\Throwable $e) {
            report($e);
            return response()->json([
                'success' => false,
                'message' => 'Account created but we could not send the verification email.',
            ], 500);
        }

        return response()->json([
            'success' => true,
            'message' => 'Account created. A 4-digit code was sent to your email. Verify with POST /api/v1/verify-otp.',
            'email' => $customer->email,
            'customer' => [
                'id' => $customer->id,
                'firstname' => $customer->firstname,
                'lastname' => $customer->lastname,
                'email' => $customer->email,
                'contact_no' => $customer->contact_no,
            ],
        ], 201);
    }

    /**
     * Verify OTP (for Flutter). Send email + otp; returns success so client can then call login.
     */
    public function verifyOtp(Request $request): JsonResponse
    {
        $request->validate([
            'email' => 'required|email',
            'otp' => 'required|string|size:4|regex:/^\d{4}$/',
        ], [
            'otp.required' => 'Please enter the 4-digit code.',
            'otp.size' => 'The code must be 4 digits.',
            'otp.regex' => 'The code must be 4 digits only.',
        ]);

        $customer = Customer::where('email', $request->email)->first();
        if (!$customer) {
            return response()->json([
                'success' => false,
                'message' => 'Account not found.',
            ], 404);
        }

        if ($customer->otp !== $request->otp) {
            return response()->json([
                'success' => false,
                'message' => 'Invalid or expired code. Please try again.',
            ], 422);
        }

        if ($customer->otp_expires_at && $customer->otp_expires_at->isPast()) {
            return response()->json([
                'success' => false,
                'message' => 'This code has expired. Request a new one with POST /api/v1/resend-otp.',
            ], 422);
        }

        $customer->update([
            'email_verified_at' => now(),
            'otp' => null,
            'otp_expires_at' => null,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Email verified. You can now log in.',
            'email' => $customer->email,
        ]);
    }

    /**
     * Resend OTP (for Flutter). Send email; generates new 4-digit code and emails it.
     */
    public function resendOtp(Request $request): JsonResponse
    {
        $request->validate([
            'email' => 'required|email',
        ]);

        $customer = Customer::where('email', $request->email)->first();
        if (!$customer) {
            return response()->json([
                'success' => false,
                'message' => 'Account not found.',
            ], 404);
        }

        $otp = str_pad((string) random_int(0, 9999), 4, '0', STR_PAD_LEFT);
        $customer->update([
            'otp' => $otp,
            'otp_expires_at' => now()->addMinutes(10),
        ]);

        try {
            Mail::to($customer->email)->send(new OtpVerificationMail($otp, $customer->email));
        } catch (\Throwable $e) {
            report($e);
            return response()->json([
                'success' => false,
                'message' => 'Could not send the new code. Please try again later.',
            ], 500);
        }

        return response()->json([
            'success' => true,
            'message' => 'A new 4-digit code has been sent to your email.',
            'email' => $customer->email,
        ]);
    }

    /**
     * End session: remove token from cache. Send same Bearer token or X-Session-Token as when logged in.
     */
    public function logout(Request $request): JsonResponse
    {
        $token = $this->getTokenFromRequest($request);
        if ($token) {
            Cache::forget(AuthenticateApiCustomer::CACHE_PREFIX . $token);
        }
        return response()->json(['success' => true, 'message' => 'Logged out.']);
    }

    private function getTokenFromRequest(Request $request): ?string
    {
        $header = $request->header('Authorization');
        if ($header && preg_match('/^Bearer\s+(.+)$/i', $header, $m)) {
            return trim($m[1]);
        }
        return $request->header('X-Session-Token') ?: null;
    }

    public function me(Request $request): JsonResponse
    {
        $user = $request->user();
        if (!$user) {
            return response()->json(['success' => false, 'message' => 'Not authenticated.'], 401);
        }
        return response()->json([
            'success' => true,
            'customer' => $this->customerProfileArray($user),
        ]);
    }

    /**
     * Get my profile (for Flutter). Same as /me, alias for clarity.
     * GET /api/v1/profile with Authorization: Bearer {token}
     */
    public function profile(Request $request): JsonResponse
    {
        $customer = $request->user();
        if (!$customer) {
            return response()->json(['success' => false, 'message' => 'Not authenticated.'], 401);
        }
        return response()->json([
            'success' => true,
            'customer' => $this->customerProfileArray($customer),
        ]);
    }

    /**
     * Fetch account of who is logged in (account information).
     * GET /api/v1/account with Authorization: Bearer {token}
     * Returns full account info: id, firstname, lastname, email, contact_no, image, image_url, status.
     */
    public function account(Request $request): JsonResponse
    {
        $customer = $request->user();
        if (!$customer) {
            return response()->json(['success' => false, 'message' => 'Not authenticated.'], 401);
        }
        return response()->json([
            'success' => true,
            'message' => 'Account information retrieved.',
            'account' => $this->customerProfileArray($customer),
        ]);
    }

    /**
     * Update address details (for Flutter).
     * PUT or POST /api/v1/address
     * Body: province, city, barangay, postal_code, street_name, label_as, reason (all optional).
     */
    public function updateAddress(Request $request): JsonResponse
    {
        $customer = $request->user();
        if (!$customer instanceof Customer) {
            return response()->json(['success' => false, 'message' => 'Not authenticated.'], 401);
        }

        $request->validate([
            'province'    => 'nullable|string|max:100',
            'city'        => 'nullable|string|max:100',
            'barangay'    => 'nullable|string|max:100',
            'postal_code' => 'nullable|string|max:20',
            'street_name' => 'nullable|string|max:255',
            'label_as'    => 'nullable|string|max:50',
            'reason'      => 'nullable|string|max:500',
        ]);

        $data = array_filter([
            'province'    => $request->filled('province') ? trim($request->province) : null,
            'city'        => $request->filled('city') ? trim($request->city) : null,
            'barangay'    => $request->filled('barangay') ? trim($request->barangay) : null,
            'postal_code' => $request->filled('postal_code') ? trim($request->postal_code) : null,
            'street_name' => $request->filled('street_name') ? trim($request->street_name) : null,
            'label_as'    => $request->filled('label_as') ? trim($request->label_as) : null,
            'reason'      => $request->filled('reason') ? trim($request->reason) : null,
        ], fn ($v) => $v !== null);

        if (empty($data)) {
            return response()->json([
                'success' => false,
                'message' => 'Provide at least one address field to update.',
            ], 422);
        }

        $customer->update($data);

        // Notify admin: customer added or updated address details
        AdminNotification::notifyAddressUpdated($customer->fresh());

        return response()->json([
            'success'  => true,
            'message'  => 'Address updated successfully.',
            'customer' => $this->customerProfileArray($customer->fresh()),
        ]);
    }

    /**
     * Update my profile (for Flutter).
     * POST /api/v1/profile/update
     * Body: multipart/form-data or JSON with firstname, lastname, contact_no; optional image (file or base64)
     */
    public function updateProfile(Request $request): JsonResponse
    {
        $customer = $request->user();
        if (!$customer instanceof Customer) {
            return response()->json(['success' => false, 'message' => 'Not authenticated.'], 401);
        }

        $request->validate([
            'firstname'  => 'required|string|max:50',
            'lastname'   => 'required|string|max:50',
            'contact_no' => 'nullable|string|max:20|regex:/^[\d\s\-+()]+$/',
            'image'      => 'nullable',
        ], [
            'firstname.required' => 'First name is required.',
            'lastname.required'   => 'Last name is required.',
        ]);

        $data = [
            'firstname'  => $request->firstname,
            'lastname'   => $request->lastname,
            'contact_no' => $request->filled('contact_no') ? trim($request->contact_no) : null,
        ];

        // Image: file upload (multipart) or base64 (JSON)
        if ($request->hasFile('image')) {
            $file = $request->file('image');
            $request->validate(['image' => 'image|mimes:jpeg,png,jpg,gif,webp|max:2048'], [
                'image.image' => 'The file must be an image.',
                'image.max'   => 'The image may not be greater than 2MB.',
            ]);
            $dir = public_path('img/customers');
            if (!is_dir($dir)) {
                mkdir($dir, 0755, true);
            }
            $name = 'customer_' . $customer->id . '_' . time() . '.' . $file->getClientOriginalExtension();
            $file->move($dir, $name);
            $data['image'] = 'img/customers/' . $name;
        } elseif ($request->filled('image') && preg_match('/^data:image\/(\w+);base64,/', $request->image, $m)) {
            $ext = $m[1] === 'jpeg' ? 'jpg' : $m[1];
            $base64 = substr($request->image, strpos($request->image, ',') + 1);
            $decoded = base64_decode($base64, true);
            if ($decoded !== false) {
                $dir = public_path('img/customers');
                if (!is_dir($dir)) {
                    mkdir($dir, 0755, true);
                }
                $name = 'customer_' . $customer->id . '_' . time() . '.' . $ext;
                if (file_put_contents($dir . DIRECTORY_SEPARATOR . $name, $decoded) !== false) {
                    $data['image'] = 'img/customers/' . $name;
                }
            }
        }

        $customer->update($data);

        // Notify admins: always "updated their Profile" for any account information change
        AdminNotification::notifyProfileUpdated($customer->fresh(), 'Profile');

        return response()->json([
            'success' => true,
            'message' => 'Profile updated successfully.',
            'customer' => $this->customerProfileArray($customer->fresh()),
        ]);
    }

    /**
     * Build customer array for API responses (profile, me, login).
     */
    private function customerProfileArray(Customer $customer): array
    {
        $imagePath = $customer->image ?? 'img/default-user.png';
        $imageUrl = $imagePath ? url($imagePath) : null;

        $parts = array_filter([
            $customer->street_name,
            $customer->barangay,
            $customer->city ? $customer->city . ' City' : null,
            $customer->province,
            $customer->postal_code,
        ]);
        $fullAddress = implode(', ', $parts) ?: null;

        return [
            'id'           => $customer->id,
            'firstname'    => $customer->firstname,
            'lastname'     => $customer->lastname,
            'email'        => $customer->email,
            'contact_no'   => $customer->contact_no,
            'image'        => $imagePath,
            'image_url'    => $imageUrl,
            'status'       => $customer->status ?? 'active',
            'province'     => $customer->province,
            'city'         => $customer->city,
            'barangay'     => $customer->barangay,
            'postal_code'  => $customer->postal_code,
            'street_name'  => $customer->street_name,
            'label_as'     => $customer->label_as,
            'reason'       => $customer->reason,
            'full_address' => $fullAddress,
        ];
    }

    /**
     * Forgot password: send OTP to email (for Flutter).
     * POST /api/v1/forgot-password { "email": "user@example.com" }
     */
    public function forgotPassword(Request $request): JsonResponse
    {
        $request->validate([
            'email' => 'required|email',
        ]);

        $customer = Customer::where('email', $request->email)->first();
        if (!$customer) {
            return response()->json([
                'success' => false,
                'message' => 'No account found with this email address.',
            ], 404);
        }

        $otp = str_pad((string) random_int(0, 9999), 4, '0', STR_PAD_LEFT);
        $customer->update([
            'otp' => $otp,
            'otp_expires_at' => now()->addMinutes(10),
        ]);

        try {
            Mail::to($customer->email)->send(new OtpVerificationMail($otp, $customer->email));
        } catch (\Throwable $e) {
            report($e);
            return response()->json([
                'success' => false,
                'message' => 'Could not send the verification code. Please try again later.',
            ], 500);
        }

        return response()->json([
            'success' => true,
            'message' => 'A 4-digit code has been sent to your email. Use POST /api/v1/forgot-password/verify-otp with email and otp.',
            'email' => $customer->email,
        ]);
    }

    /**
     * Forgot password: resend OTP (for Flutter).
     * POST /api/v1/forgot-password/resend-otp { "email": "user@example.com" }
     */
    public function resendForgotPasswordOtp(Request $request): JsonResponse
    {
        $request->validate([
            'email' => 'required|email',
        ]);

        $customer = Customer::where('email', $request->email)->first();
        if (!$customer) {
            return response()->json([
                'success' => false,
                'message' => 'No account found with this email address.',
            ], 404);
        }

        $otp = str_pad((string) random_int(0, 9999), 4, '0', STR_PAD_LEFT);
        $customer->update([
            'otp' => $otp,
            'otp_expires_at' => now()->addMinutes(10),
        ]);

        try {
            Mail::to($customer->email)->send(new OtpVerificationMail($otp, $customer->email));
        } catch (\Throwable $e) {
            report($e);
            return response()->json([
                'success' => false,
                'message' => 'Could not send the new code. Please try again later.',
            ], 500);
        }

        return response()->json([
            'success' => true,
            'message' => 'A new 4-digit code has been sent to your email.',
            'email' => $customer->email,
        ]);
    }

    /**
     * Forgot password: verify OTP and get a short-lived reset token (for Flutter).
     * POST /api/v1/forgot-password/verify-otp { "email": "user@example.com", "otp": "1234" }
     * Returns reset_token; use it in POST /api/v1/forgot-password/reset-password.
     */
    public function verifyForgotPasswordOtp(Request $request): JsonResponse
    {
        $request->validate([
            'email' => 'required|email',
            'otp' => 'required|string|size:4|regex:/^\d{4}$/',
        ], [
            'otp.required' => 'Please enter the 4-digit code.',
            'otp.size' => 'The code must be 4 digits.',
            'otp.regex' => 'The code must be 4 digits only.',
        ]);

        $customer = Customer::where('email', $request->email)->first();
        if (!$customer) {
            return response()->json([
                'success' => false,
                'message' => 'Account not found.',
            ], 404);
        }

        if ($customer->otp !== $request->otp) {
            return response()->json([
                'success' => false,
                'message' => 'Invalid or expired code. Please try again.',
            ], 422);
        }

        if ($customer->otp_expires_at && $customer->otp_expires_at->isPast()) {
            return response()->json([
                'success' => false,
                'message' => 'This code has expired. Request a new one with POST /api/v1/forgot-password/resend-otp.',
            ], 422);
        }

        $customer->update(['otp' => null, 'otp_expires_at' => null]);

        $resetToken = Str::random(64);
        Cache::put('password_reset:' . $resetToken, $customer->email, now()->addMinutes(15));

        return response()->json([
            'success' => true,
            'message' => 'Code verified. Use the reset_token in POST /api/v1/forgot-password/reset-password to set your new password.',
            'reset_token' => $resetToken,
            'expires_in_minutes' => 15,
        ]);
    }

    /**
     * Forgot password: set new password using reset_token (for Flutter).
     * POST /api/v1/forgot-password/reset-password { "reset_token": "...", "password": "newpass", "password_confirmation": "newpass" }
     */
    public function resetPassword(Request $request): JsonResponse
    {
        $request->validate([
            'reset_token' => 'required|string',
            'password' => 'required|string|confirmed|min:6',
        ], [
            'password.required' => 'Password is required.',
            'password.confirmed' => 'Passwords do not match.',
            'password.min' => 'Password must be at least 6 characters.',
        ]);

        $email = Cache::get('password_reset:' . $request->reset_token);
        if (!$email) {
            return response()->json([
                'success' => false,
                'message' => 'Invalid or expired reset token. Please start the forgot-password flow again.',
            ], 422);
        }

        $customer = Customer::where('email', $email)->first();
        if (!$customer) {
            Cache::forget('password_reset:' . $request->reset_token);
            return response()->json([
                'success' => false,
                'message' => 'Account not found.',
            ], 404);
        }

        $customer->update(['password' => Hash::make($request->password)]);
        Cache::forget('password_reset:' . $request->reset_token);

        return response()->json([
            'success' => true,
            'message' => 'Your password has been updated. You can now log in.',
        ]);
    }

    // --- Change Password (logged-in customer: email → OTP → verify → current + new password → keep logged in or re-login) ---

    private const CHANGE_PASSWORD_VERIFIED_PREFIX = 'change_password_verified:';
    private const CHANGE_PASSWORD_VERIFIED_TTL_MINUTES = 10;

    /**
     * Change password step 1: send OTP to email (for Flutter).
     * POST /api/v1/change-password/send-otp
     * Headers: Authorization: Bearer {token}
     * Body: { "email": "user@example.com" } — must match logged-in customer.
     */
    public function changePasswordSendOtp(Request $request): JsonResponse
    {
        $customer = $request->user();
        if (!$customer instanceof Customer) {
            return response()->json(['success' => false, 'message' => 'Not authenticated.'], 401);
        }

        $request->validate([
            'email' => 'required|email',
        ], [
            'email.required' => 'Please enter your email address.',
            'email.email' => 'Please enter a valid email address.',
        ]);

        if (strcasecmp($customer->email, $request->email) !== 0) {
            return response()->json([
                'success' => false,
                'message' => 'This email does not match your account.',
            ], 422);
        }

        $otp = str_pad((string) random_int(0, 9999), 4, '0', STR_PAD_LEFT);
        $customer->update([
            'otp' => $otp,
            'otp_expires_at' => now()->addMinutes(10),
        ]);

        try {
            Mail::to($customer->email)->send(new OtpVerificationMail($otp, $customer->email));
        } catch (\Throwable $e) {
            report($e);
            return response()->json([
                'success' => false,
                'message' => 'Could not send the verification code. Please try again later.',
            ], 500);
        }

        return response()->json([
            'success' => true,
            'message' => 'A 4-digit code has been sent to your email. Use POST /api/v1/change-password/verify-otp with otp.',
            'email' => $customer->email,
        ]);
    }

    /**
     * Change password step 2: verify OTP (for Flutter).
     * POST /api/v1/change-password/verify-otp
     * Headers: Authorization: Bearer {token}
     * Body: { "otp": "1234" }
     */
    public function changePasswordVerifyOtp(Request $request): JsonResponse
    {
        $customer = $request->user();
        if (!$customer instanceof Customer) {
            return response()->json(['success' => false, 'message' => 'Not authenticated.'], 401);
        }

        $request->validate([
            'otp' => 'required|string|size:4|regex:/^\d{4}$/',
        ], [
            'otp.required' => 'Please enter the 4-digit code.',
            'otp.size' => 'The code must be 4 digits.',
            'otp.regex' => 'The code must be 4 digits only.',
        ]);

        if ($customer->otp !== $request->otp) {
            return response()->json([
                'success' => false,
                'message' => 'Invalid or expired code. Please try again.',
            ], 422);
        }

        if ($customer->otp_expires_at && $customer->otp_expires_at->isPast()) {
            return response()->json([
                'success' => false,
                'message' => 'This code has expired. Request a new one with POST /api/v1/change-password/send-otp.',
            ], 422);
        }

        $customer->update(['otp' => null, 'otp_expires_at' => null]);
        Cache::put(self::CHANGE_PASSWORD_VERIFIED_PREFIX . $customer->id, 1, now()->addMinutes(self::CHANGE_PASSWORD_VERIFIED_TTL_MINUTES));

        return response()->json([
            'success' => true,
            'message' => 'Code verified. Use POST /api/v1/change-password/update with current_password, password, password_confirmation, and keep_logged_in.',
            'expires_in_minutes' => self::CHANGE_PASSWORD_VERIFIED_TTL_MINUTES,
        ]);
    }

    /**
     * Change password: resend OTP (for Flutter).
     * POST /api/v1/change-password/resend-otp
     * Headers: Authorization: Bearer {token}
     * Body: { "email": "user@example.com" } — must match logged-in customer.
     */
    public function changePasswordResendOtp(Request $request): JsonResponse
    {
        $customer = $request->user();
        if (!$customer instanceof Customer) {
            return response()->json(['success' => false, 'message' => 'Not authenticated.'], 401);
        }

        $request->validate([
            'email' => 'required|email',
        ]);

        if (strcasecmp($customer->email, $request->email) !== 0) {
            return response()->json([
                'success' => false,
                'message' => 'This email does not match your account.',
            ], 422);
        }

        $otp = str_pad((string) random_int(0, 9999), 4, '0', STR_PAD_LEFT);
        $customer->update([
            'otp' => $otp,
            'otp_expires_at' => now()->addMinutes(10),
        ]);

        try {
            Mail::to($customer->email)->send(new OtpVerificationMail($otp, $customer->email));
        } catch (\Throwable $e) {
            report($e);
            return response()->json([
                'success' => false,
                'message' => 'Could not send the new code. Please try again later.',
            ], 500);
        }

        return response()->json([
            'success' => true,
            'message' => 'A new 4-digit code has been sent to your email.',
            'email' => $customer->email,
        ]);
    }

    /**
     * Change password step 3: set new password (for Flutter).
     * Must have called verify-otp first (within last 10 minutes).
     * POST /api/v1/change-password/update
     * Headers: Authorization: Bearer {token}
     * Body: { "current_password": "...", "password": "newpass", "password_confirmation": "newpass", "keep_logged_in": true }
     * keep_logged_in: if true, token stays valid; if false, token is invalidated and client should log in again.
     */
    public function changePasswordUpdate(Request $request): JsonResponse
    {
        $customer = $request->user();
        if (!$customer instanceof Customer) {
            return response()->json(['success' => false, 'message' => 'Not authenticated.'], 401);
        }

        $verified = Cache::get(self::CHANGE_PASSWORD_VERIFIED_PREFIX . $customer->id);
        if (!$verified) {
            return response()->json([
                'success' => false,
                'message' => 'Please verify the OTP first. Use POST /api/v1/change-password/send-otp then verify-otp.',
            ], 422);
        }

        $request->validate([
            'current_password' => 'required',
            'password' => 'required|string|confirmed|min:6',
        ], [
            'current_password.required' => 'Please enter your current password.',
            'password.required' => 'New password is required.',
            'password.confirmed' => 'New passwords do not match.',
            'password.min' => 'New password must be at least 6 characters.',
        ]);

        if (!Hash::check($request->current_password, $customer->password)) {
            return response()->json([
                'success' => false,
                'message' => 'Current password is incorrect.',
            ], 422);
        }

        $customer->update(['password' => Hash::make($request->password)]);
        Cache::forget(self::CHANGE_PASSWORD_VERIFIED_PREFIX . $customer->id);

        $keepLoggedIn = $request->boolean('keep_logged_in');

        if (!$keepLoggedIn) {
            $token = $this->getTokenFromRequest($request);
            if ($token) {
                Cache::forget(AuthenticateApiCustomer::CACHE_PREFIX . $token);
            }
            return response()->json([
                'success' => true,
                'message' => 'Your password has been updated. Please log in again.',
                'logged_out' => true,
            ]);
        }

        return response()->json([
            'success' => true,
            'message' => 'Your password has been updated. You are still logged in.',
            'customer' => $this->customerProfileArray($customer->fresh()),
            'token' => $this->getTokenFromRequest($request),
            'logged_out' => false,
        ]);
    }
}
