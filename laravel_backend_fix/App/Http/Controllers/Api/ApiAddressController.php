<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Customer;
use App\Models\AdminNotification;
use App\Models\CustomerAddress;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ApiAddressController extends Controller
{
    /**
     * List all addresses for the authenticated customer.
     * GET /api/v1/addresses
     */
    public function index(Request $request): JsonResponse
    {
        $customer = $request->user();
        if (!$customer instanceof Customer) {
            return response()->json(['success' => false, 'message' => 'Not authenticated.'], 401);
        }

        $addresses = $customer->addresses()
            ->orderBy('is_default', 'desc')
            ->orderBy('created_at', 'asc')
            ->get()
            ->map(fn (CustomerAddress $a) => $this->addressToArray($a));

        return response()->json([
            'success' => true,
            'data' => [
                'addresses' => $addresses,
                'count' => $addresses->count(),
            ],
        ]);
    }

    /**
     * Add a new address.
     * POST /api/v1/addresses
     * Body: firstname, lastname, contact_no, province, city, barangay, postal_code, street_name, label_as, reason, is_default (optional).
     */
    public function store(Request $request): JsonResponse
    {
        $customer = $request->user();
        if (!$customer instanceof Customer) {
            return response()->json(['success' => false, 'message' => 'Not authenticated.'], 401);
        }

        $request->validate([
            'firstname'   => 'nullable|string|max:50',
            'lastname'    => 'nullable|string|max:50',
            'contact_no'  => 'nullable|string|max:20|regex:/^[\d\s\-+()]+$/',
            'province'    => 'nullable|string|max:100',
            'city'        => 'nullable|string|max:100',
            'barangay'    => 'nullable|string|max:100',
            'postal_code' => 'nullable|string|max:20',
            'street_name' => 'nullable|string|max:255',
            'label_as'    => 'nullable|string|max:50',
            'reason'      => 'nullable|string|max:500',
            'is_default'  => 'nullable|boolean',
        ]);

        $isDefault = $request->boolean('is_default');
        if ($isDefault) {
            $customer->addresses()->update(['is_default' => false]);
        } elseif ($customer->addresses()->count() === 0) {
            $isDefault = true; // first address is default
        }

        $address = $customer->addresses()->create([
            'firstname'   => $request->filled('firstname') ? trim($request->firstname) : null,
            'lastname'    => $request->filled('lastname') ? trim($request->lastname) : null,
            'contact_no'  => $request->filled('contact_no') ? trim($request->contact_no) : null,
            'province'    => $request->filled('province') ? trim($request->province) : null,
            'city'        => $request->filled('city') ? trim($request->city) : null,
            'barangay'    => $request->filled('barangay') ? trim($request->barangay) : null,
            'postal_code' => $request->filled('postal_code') ? trim($request->postal_code) : null,
            'street_name' => $request->filled('street_name') ? trim($request->street_name) : null,
            'label_as'    => $request->filled('label_as') ? trim($request->label_as) : null,
            'reason'      => $request->filled('reason') ? trim($request->reason) : null,
            'is_default'  => $isDefault,
        ]);

        AdminNotification::notifyAddressUpdated($customer->fresh());

        return response()->json([
            'success' => true,
            'message' => 'Address added successfully.',
            'data' => $this->addressToArray($address),
        ], 201);
    }

    /**
     * Get a single address (must belong to the customer).
     * GET /api/v1/addresses/{id}
     */
    public function show(Request $request, int $id): JsonResponse
    {
        $customer = $request->user();
        if (!$customer instanceof Customer) {
            return response()->json(['success' => false, 'message' => 'Not authenticated.'], 401);
        }

        $address = $customer->addresses()->find($id);
        if (!$address) {
            return response()->json([
                'success' => false,
                'message' => 'Address not found.',
            ], 404);
        }

        return response()->json([
            'success' => true,
            'data' => $this->addressToArray($address),
        ]);
    }

    /**
     * Update an address.
     * PUT/PATCH /api/v1/addresses/{id}
     */
    public function update(Request $request, int $id): JsonResponse
    {
        $customer = $request->user();
        if (!$customer instanceof Customer) {
            return response()->json(['success' => false, 'message' => 'Not authenticated.'], 401);
        }

        $address = $customer->addresses()->find($id);
        if (!$address) {
            return response()->json([
                'success' => false,
                'message' => 'Address not found.',
            ], 404);
        }

        $request->validate([
            'firstname'   => 'nullable|string|max:50',
            'lastname'    => 'nullable|string|max:50',
            'contact_no'  => 'nullable|string|max:20|regex:/^[\d\s\-+()]+$/',
            'province'    => 'nullable|string|max:100',
            'city'        => 'nullable|string|max:100',
            'barangay'    => 'nullable|string|max:100',
            'postal_code' => 'nullable|string|max:20',
            'street_name' => 'nullable|string|max:255',
            'label_as'    => 'nullable|string|max:50',
            'reason'      => 'nullable|string|max:500',
            'is_default'  => 'nullable|boolean',
        ]);

        $data = array_filter([
            'firstname'   => $request->filled('firstname') ? trim($request->firstname) : null,
            'lastname'    => $request->filled('lastname') ? trim($request->lastname) : null,
            'contact_no'  => $request->filled('contact_no') ? trim($request->contact_no) : null,
            'province'    => $request->filled('province') ? trim($request->province) : null,
            'city'        => $request->filled('city') ? trim($request->city) : null,
            'barangay'    => $request->filled('barangay') ? trim($request->barangay) : null,
            'postal_code' => $request->filled('postal_code') ? trim($request->postal_code) : null,
            'street_name' => $request->filled('street_name') ? trim($request->street_name) : null,
            'label_as'    => $request->filled('label_as') ? trim($request->label_as) : null,
            'reason'      => $request->filled('reason') ? trim($request->reason) : null,
        ], fn ($v) => $v !== null);

        if ($request->has('is_default') && $request->boolean('is_default')) {
            $customer->addresses()->where('id', '!=', $id)->update(['is_default' => false]);
            $data['is_default'] = true;
        }

        $address->update($data);

        AdminNotification::notifyAddressUpdated($customer->fresh());

        return response()->json([
            'success' => true,
            'message' => 'Address updated successfully.',
            'data' => $this->addressToArray($address->fresh()),
        ]);
    }

    /**
     * Delete an address.
     * DELETE /api/v1/addresses/{id}
     */
    public function destroy(Request $request, int $id): JsonResponse
    {
        $customer = $request->user();
        if (!$customer instanceof Customer) {
            return response()->json(['success' => false, 'message' => 'Not authenticated.'], 401);
        }

        $address = $customer->addresses()->find($id);
        if (!$address) {
            return response()->json([
                'success' => false,
                'message' => 'Address not found.',
            ], 404);
        }

        $wasDefault = $address->is_default;
        $address->delete();

        // If we deleted the default, set the first remaining as default
        if ($wasDefault) {
            $first = $customer->addresses()->orderBy('created_at')->first();
            if ($first) {
                $first->update(['is_default' => true]);
            }
        }

        return response()->json([
            'success' => true,
            'message' => 'Address deleted.',
        ]);
    }

    /**
     * Set an address as the default.
     * POST /api/v1/addresses/{id}/default
     */
    public function setDefault(Request $request, int $id): JsonResponse
    {
        $customer = $request->user();
        if (!$customer instanceof Customer) {
            return response()->json(['success' => false, 'message' => 'Not authenticated.'], 401);
        }

        $address = $customer->addresses()->find($id);
        if (!$address) {
            return response()->json([
                'success' => false,
                'message' => 'Address not found.',
            ], 404);
        }

        $customer->addresses()->update(['is_default' => false]);
        $address->update(['is_default' => true]);

        AdminNotification::notifyAddressUpdated($customer->fresh());

        return response()->json([
            'success' => true,
            'message' => 'Default address updated.',
            'data' => $this->addressToArray($address->fresh()),
        ]);
    }

    private function addressToArray(CustomerAddress $address): array
    {
        return [
            'id'           => $address->id,
            'customer_id'  => $address->customer_id,
            'firstname'    => $address->firstname,
            'lastname'     => $address->lastname,
            'contact_no'   => $address->contact_no,
            'province'     => $address->province,
            'city'         => $address->city,
            'barangay'     => $address->barangay,
            'postal_code'  => $address->postal_code,
            'street_name'  => $address->street_name,
            'label_as'     => $address->label_as,
            'reason'       => $address->reason,
            'is_default'   => $address->is_default,
            'full_address' => $address->full_address,
            'created_at'   => $address->created_at?->toIso8601String(),
            'updated_at'   => $address->updated_at?->toIso8601String(),
        ];
    }
}
