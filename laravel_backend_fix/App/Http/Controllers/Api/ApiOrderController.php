<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Customer;
use App\Models\CustomerNotification;
use App\Models\AdminNotification;
use App\Models\Order;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

class ApiOrderController extends Controller
{
    /**
     * List orders for the authenticated customer (for Flutter).
     */
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();
        if (!$user instanceof Customer) {
            return response()->json(['success' => false, 'message' => 'Invalid user.'], 401);
        }
        $orders = Order::where('customer_name', $user->firstname . ' ' . $user->lastname)
            ->orWhere('customer_phone', $user->contact_no)
            ->orderBy('created_at', 'desc')
            ->get()
            ->map(fn (Order $order) => $this->formatOrderForApi($order));
        return response()->json(['success' => true, 'data' => $orders]);
    }

    /**
     * Create order (for Flutter). Notifies customer and admin.
     */
    public function store(Request $request): JsonResponse
    {
        $request->validate([
            'product_name' => 'required|string|max:255',
            'product_type' => 'required|string|max:255',
            'gallon_size' => 'required|string|max:50',
            'delivery_date' => 'required|date',
            'delivery_time' => 'required|string',
            'delivery_address' => 'required|string',
            'amount' => 'required|numeric|min:0',
            'payment_method' => 'required|string|max:50',
        ]);

        $user = $request->user();
        $customerName = $request->customer_name ?? ($user ? $user->firstname . ' ' . $user->lastname : 'Guest');
        $customerPhone = $request->customer_phone ?? ($user?->contact_no ?? '');
        $customerImage = $request->customer_image ?? 'img/default-user.png';

        $flavor = \App\Models\Flavor::where('name', $request->product_name)->first();
        $productImage = $flavor?->image ?? 'img/default-product.png';

        $order = Order::create([
            'transaction_id' => strtoupper(Str::random(10)),
            'product_name' => $request->product_name,
            'product_type' => $request->product_type,
            'gallon_size' => $request->gallon_size,
            'product_image' => $productImage,
            'customer_name' => $customerName,
            'customer_phone' => $customerPhone,
            'customer_image' => $customerImage,
            'delivery_date' => $request->delivery_date,
            'delivery_time' => $request->delivery_time,
            'delivery_address' => $request->delivery_address,
            'amount' => $request->amount,
            'payment_method' => $request->payment_method,
            'status' => 'pending',
        ]);

        // Notify customer when order is placed (if authenticated)
        if ($user instanceof Customer) {
            CustomerNotification::create([
                'customer_id'   => $user->id,
                'type'          => CustomerNotification::TYPE_ORDER_PLACED,
                'title'         => $order->product_name,
                'message'       => 'Your order has been placed successfully.',
                'image_url'     => $productImage,
                'related_type'  => 'Order',
                'related_id'    => $order->id,
                'data'          => ['transaction_id' => $order->transaction_id],
            ]);
        }

        // Notify admin: new order placed
        AdminNotification::notifyNewOrder($order);

        return response()->json(['success' => true, 'data' => $this->formatOrderForApi($order)], 201);
    }

    /**
     * Return only fields needed for order display (list/detail).
     */
    private function formatOrderForApi(Order $order): array
    {
        return [
            'id'               => $order->id,
            'transaction_id'   => $order->transaction_id,
            'product_name'     => $order->product_name,
            'product_type'     => $order->product_type,
            'gallon_size'      => $order->gallon_size,
            'product_image'    => $order->product_image,
            'delivery_date'    => $order->delivery_date?->format('Y-m-d'),
            'delivery_time'    => $order->delivery_time,
            'delivery_address' => $order->delivery_address,
            'amount'           => (float) $order->amount,
            'payment_method'   => $order->payment_method,
            'status'           => $order->status,
            'created_at'       => $order->created_at?->toIso8601String(),
        ];
    }

    public function show(Request $request, int $id): JsonResponse
    {
        $order = Order::find($id);
        if (!$order) {
            return response()->json(['success' => false, 'message' => 'Order not found.'], 404);
        }
        return response()->json(['success' => true, 'data' => $this->formatOrderForApi($order)]);
    }
}
