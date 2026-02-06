<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ChatMessage;
use App\Models\Customer;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ApiAdminChatController extends Controller
{
    /**
     * List customers with chat conversations (for admin panel).
     * GET /api/v1/admin/chat/customers?page=1&per_page=20
     * Each customer includes last message preview and unread count (from customer).
     */
    public function customers(Request $request): JsonResponse
    {
        $perPage = min((int) $request->get('per_page', 20), 50);

        // Customers who have at least one chat message, ordered by latest message
        $query = Customer::query()
            ->whereHas('chatMessages')
            ->withCount(['chatMessages as unread_from_customer' => function ($q) {
                $q->where('sender_type', ChatMessage::SENDER_CUSTOMER)
                    ->whereNull('read_at');
            }])
            ->with(['chatMessages' => fn ($q) => $q->orderByDesc('created_at')->limit(1)])
            ->orderByDesc(DB::raw('(SELECT MAX(created_at) FROM chat_messages WHERE chat_messages.customer_id = customers.id)'));

        $customers = $query->paginate($perPage);

        $items = $customers->getCollection()->map(function (Customer $c) {
            $lastMsg = $c->chatMessages->first();
            return [
                'id' => $c->id,
                'name' => trim($c->firstname . ' ' . $c->lastname) ?: ($c->firstname ?? $c->lastname ?? 'Customer'),
                'email' => $c->email ?? null,
                'contact_no' => $c->contact_no ?? null,
                'unread_count' => $c->unread_from_customer ?? 0,
                'last_message' => $lastMsg ? [
                    'id' => $lastMsg->id,
                    'sender_type' => $lastMsg->sender_type,
                    'body' => $lastMsg->body,
                    'image_url' => $lastMsg->image_path ? asset('storage/' . $lastMsg->image_path) : null,
                    'created_at' => $lastMsg->created_at->toIso8601String(),
                ] : null,
            ];
        })->values()->all();

        return response()->json([
            'success' => true,
            'data' => $items,
            'meta' => [
                'current_page' => $customers->currentPage(),
                'last_page' => $customers->lastPage(),
                'per_page' => $customers->perPage(),
                'total' => $customers->total(),
            ],
        ]);
    }

    /**
     * Get chat messages with a specific customer.
     * GET /api/v1/admin/chat/customers/{customer_id}/messages?page=1&per_page=50
     */
    public function messages(Request $request, int $customerId): JsonResponse
    {
        $customer = Customer::find($customerId);
        if (!$customer) {
            return response()->json(['success' => false, 'message' => 'Customer not found.'], 404);
        }

        $perPage = min((int) $request->get('per_page', 50), 100);
        $messages = $customer->chatMessages()
            ->orderBy('created_at')
            ->paginate($perPage);

        $items = $messages->getCollection()->map(fn (ChatMessage $m) => $this->formatMessage($m))->values()->all();

        return response()->json([
            'success' => true,
            'data' => [
                'customer' => [
                    'id' => $customer->id,
                    'name' => trim($customer->firstname . ' ' . $customer->lastname) ?: ($customer->firstname ?? $customer->lastname ?? 'Customer'),
                    'email' => $customer->email ?? null,
                    'contact_no' => $customer->contact_no ?? null,
                ],
                'messages' => $items,
            ],
            'meta' => [
                'current_page' => $messages->currentPage(),
                'last_page' => $messages->lastPage(),
                'per_page' => $messages->perPage(),
                'total' => $messages->total(),
            ],
        ]);
    }

    /**
     * Send a message to a customer (admin → customer).
     * POST /api/v1/admin/chat/customers/{customer_id}/messages
     * body: optional text, image: optional file (multipart)
     */
    public function store(Request $request, int $customerId): JsonResponse
    {
        $customer = Customer::find($customerId);
        if (!$customer) {
            return response()->json(['success' => false, 'message' => 'Customer not found.'], 404);
        }

        $body = $request->input('body');
        $imagePath = null;

        if ($request->hasFile('image')) {
            $file = $request->file('image');
            if ($file->isValid() && str_starts_with($file->getMimeType(), 'image/')) {
                $path = $file->store('chat', 'public');
                if ($path) {
                    $imagePath = $path;
                }
            }
        }

        if (empty(trim($body ?? '')) && !$imagePath) {
            return response()->json([
                'success' => false,
                'message' => 'Provide a message (body) or an image.',
            ], 422);
        }

        $message = $customer->chatMessages()->create([
            'sender_type' => ChatMessage::SENDER_ADMIN,
            'body' => trim($body ?? '') ?: null,
            'image_path' => $imagePath,
        ]);

        return response()->json([
            'success' => true,
            'data' => $this->formatMessage($message),
        ]);
    }

    /**
     * Mark customer messages as read (admin has read them).
     * POST /api/v1/admin/chat/customers/{customer_id}/read
     */
    public function markRead(Request $request, int $customerId): JsonResponse
    {
        $customer = Customer::find($customerId);
        if (!$customer) {
            return response()->json(['success' => false, 'message' => 'Customer not found.'], 404);
        }

        $customer->chatMessages()
            ->where('sender_type', ChatMessage::SENDER_CUSTOMER)
            ->whereNull('read_at')
            ->update(['read_at' => now()]);

        return response()->json([
            'success' => true,
            'message' => 'Marked as read.',
        ]);
    }

    private function formatMessage(ChatMessage $m): array
    {
        $imageUrl = null;
        if ($m->image_path) {
            $imageUrl = asset('storage/' . $m->image_path);
        }
        return [
            'id' => $m->id,
            'sender_type' => $m->sender_type,
            'body' => $m->body,
            'image_url' => $imageUrl,
            'created_at' => $m->created_at->toIso8601String(),
            'read_at' => $m->read_at?->toIso8601String(),
        ];
    }
}
