<?php

namespace App\Http\Controllers;

use App\Models\PesanLaporan;
use App\Models\LaporanKeluhan;
use App\Models\User;
use App\Services\FirebaseCloudMessagingService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Validator;

class PesanController extends Controller
{
    private static array $pemerintahRoles = ['admin', 'sekretaris', 'kepala_desa'];

    public function __construct(private FirebaseCloudMessagingService $fcmService)
    {
    }

    private function isPemerintah($user): bool
    {
        return in_array($user->role, self::$pemerintahRoles, true);
    }

    public function index($laporanId)
    {
        $user = Auth::user();
        $laporan = LaporanKeluhan::find($laporanId);

        if (!$laporan) {
            return response()->json(['message' => 'Laporan tidak ditemukan'], 404);
        }

        if ($user->role === 'masyarakat' && $laporan->user_id !== $user->id) {
            return response()->json(['message' => 'Tidak memiliki akses'], 403);
        }

        $pesan = PesanLaporan::with('user:id,name,role')
            ->where('laporan_id', $laporanId)
            ->orderBy('created_at', 'asc')
            ->get();

        if ($this->isPemerintah($user)) {
            PesanLaporan::where('laporan_id', $laporanId)
                ->where('pengirim_role', 'masyarakat')
                ->where('is_read', false)
                ->update(['is_read' => true]);
        } else {
            PesanLaporan::where('laporan_id', $laporanId)
                ->where('pengirim_role', '!=', 'masyarakat')
                ->where('is_read', false)
                ->update(['is_read' => true]);
        }

        return response()->json($pesan);
    }

    public function store(Request $request, $laporanId)
    {
        $user = Auth::user();
        $laporan = LaporanKeluhan::find($laporanId);

        if (!$laporan) {
            return response()->json(['message' => 'Laporan tidak ditemukan'], 404);
        }

        if ($user->role === 'masyarakat' && $laporan->user_id !== $user->id) {
            return response()->json(['message' => 'Tidak memiliki akses'], 403);
        }

        $validator = Validator::make($request->all(), [
            'pesan' => 'required|string|max:1000',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $pengirimRole = $this->isPemerintah($user) ? $user->role : 'masyarakat';

        $pesan = PesanLaporan::create([
            'laporan_id' => $laporanId,
            'user_id' => $user->id,
            'pesan' => $request->pesan,
            'pengirim_role' => $pengirimRole,
            'is_read' => false,
        ]);

        $pesan->load('user:id,name,role');

        $this->sendPushNotification($laporan, $user, $request->pesan);

        return response()->json([
            'message' => 'Pesan berhasil dikirim',
            'pesan' => $pesan,
        ], 201);
    }

    public function unreadCount()
    {
        $user = Auth::user();

        if ($this->isPemerintah($user)) {
            $count = PesanLaporan::where('pengirim_role', 'masyarakat')
                ->where('is_read', false)
                ->count();
        } else {
            $laporanIds = LaporanKeluhan::where('user_id', $user->id)
                ->pluck('id');

            $count = PesanLaporan::whereIn('laporan_id', $laporanIds)
                ->where('pengirim_role', '!=', 'masyarakat')
                ->where('is_read', false)
                ->count();
        }

        return response()->json(['unread_count' => $count]);
    }

    public function notifications()
    {
        $user = Auth::user();

        $query = PesanLaporan::with([
                'user:id,name,role',
                'laporan:id,user_id,judul,status,created_at'
            ])
            ->where('is_read', false)
            ->orderBy('created_at', 'desc');

        if ($this->isPemerintah($user)) {
            $query->where('pengirim_role', 'masyarakat');
        } else {
            $query->where('pengirim_role', '!=', 'masyarakat')
                ->whereHas('laporan', function ($q) use ($user) {
                    $q->where('user_id', $user->id);
                });
        }

        $items = $query->get()
            ->groupBy('laporan_id')
            ->map(function ($messages) {
                $latest = $messages->first();

                return [
                    'id' => $latest->id,
                    'laporan_id' => $latest->laporan_id,
                    'judul_laporan' => $latest->laporan?->judul,
                    'pesan' => $latest->pesan,
                    'pengirim_role' => $latest->pengirim_role,
                    'pengirim_nama' => $latest->user?->name,
                    'unread_count' => $messages->count(),
                    'created_at' => $latest->created_at,
                ];
            })
            ->values();

        return response()->json($items);
    }

    private function sendPushNotification(LaporanKeluhan $laporan, $sender, string $message): void
    {
        if ($this->isPemerintah($sender)) {
            $recipient = $laporan->user;
            if (!$recipient || empty($recipient->fcm_token)) {
                return;
            }

            $roleName = match ($sender->role) {
                'sekretaris' => 'sekretaris',
                'kepala_desa' => 'kepala desa',
                default => 'admin',
            };

            $this->fcmService->sendToToken(
                $recipient->fcm_token,
                "Pesan baru dari $roleName",
                $message,
                [
                    'type' => 'chat',
                    'laporan_id' => (string) $laporan->id,
                    'role' => 'masyarakat',
                ]
            );

            return;
        }

        $pemerintah = User::whereIn('role', self::$pemerintahRoles)
            ->where('is_active', true)
            ->whereNotNull('fcm_token')
            ->get();

        foreach ($pemerintah as $staff) {
            $this->fcmService->sendToToken(
                $staff->fcm_token,
                'Pesan baru dari masyarakat',
                $message,
                [
                    'type' => 'chat',
                    'laporan_id' => (string) $laporan->id,
                    'role' => $staff->role,
                    'nama_pengirim' => $sender->name,
                ]
            );
        }
    }
}
