<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\AdminNotification;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ApiAdminNotificationController extends Controller
{
    /**
     * List admin notifications (for admin panel / dashboard).
     * GET /api/v1/admin/notifications
     * Query: ?page=1&per_page=20&unread_only=0
     * Protect this route with your admin auth middleware (e.g. auth:sanctum + admin role).
     */
    public function index(Request $request): JsonResponse
    {
        $perPage = min((int) $request->get('per_page', 20), 50);
        $unreadOnly = $request->boolean('unread_only');

        $query = AdminNotification::query()->orderBy('created_at', 'desc');

        if ($unreadOnly) {
            $query->unread();
        }

        $notifications = $query->paginate($perPage);
        $unreadCount = AdminNotification::unread()->count();

        return response()->json([
            'success' => true,
            'data' => $notifications->items(),
            'meta' => [
                'current_page' => $notifications->currentPage(),
                'last_page' => $notifications->lastPage(),
                'per_page' => $notifications->perPage(),
                'total' => $notifications->total(),
            ],
            'unread_count' => $unreadCount,
        ]);
    }

    /**
     * Get unread count only (for admin badge).
     * GET /api/v1/admin/notifications/unread-count
     */
    public function unreadCount(Request $request): JsonResponse
    {
        $count = AdminNotification::unread()->count();

        return response()->json([
            'success' => true,
            'unread_count' => $count,
        ]);
    }

    /**
     * Mark a single notification as read.
     * POST /api/v1/admin/notifications/{id}/read
     */
    public function markRead(Request $request, int $id): JsonResponse
    {
        $notification = AdminNotification::find($id);

        if (!$notification) {
            return response()->json(['success' => false, 'message' => 'Notification not found.'], 404);
        }

        $notification->markAsRead();

        return response()->json(['success' => true, 'message' => 'Marked as read.']);
    }

    /**
     * Mark all admin notifications as read.
     * POST /api/v1/admin/notifications/read-all
     */
    public function markAllRead(Request $request): JsonResponse
    {
        AdminNotification::unread()->update(['read_at' => now()]);

        return response()->json(['success' => true, 'message' => 'All marked as read.']);
    }
}
