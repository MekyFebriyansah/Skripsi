<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Database\QueryException;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Validator;

class AuthController extends Controller
{
    private function friendlyDbError(\Throwable $e): ?string
    {
        if (!$e instanceof QueryException) {
            return null;
        }

        $msg = $e->getMessage();
        if (str_contains($msg, 'actively refused') || str_contains($msg, '[2002]')) {
            return 'Database MySQL belum berjalan. Buka Laragon → klik Start All atau nyalakan MySQL, lalu coba login lagi.';
        }
        if (str_contains($msg, 'Unknown database')) {
            return 'Database belum dibuat. Jalankan: php artisan migrate di folder backend-keluhan.';
        }

        return null;
    }

    private function userPayload(User $user): array
    {
        return [
            'id'            => $user->id,
            'name'          => $user->name,
            'email'         => $user->email,
            'nik'           => $user->nik,
            'no_hp'         => $user->no_hp,
            'role'          => $user->role,
            'profile_photo' => $user->profile_photo,
        ];
    }

    // Register
    public function register(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:255',
            'nik' => 'required|string|unique:users',
            'no_hp' => 'required|string|unique:users',
            'email' => 'nullable|email|unique:users',
            'password' => 'required|string|min:6',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $user = User::create([
            'name' => $request->name,
            'nik' => $request->nik,
            'no_hp' => $request->no_hp,
            'email' => $request->email,
            'password' => Hash::make($request->password),
            'role' => 'masyarakat',
        ]);

        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'message' => 'Registrasi berhasil',
            'user' => $this->userPayload($user),
            'token' => $token,
            'role' => $user->role,
        ], 201);
    }

    // Login
    public function login(Request $request)
    {
        try {
            $credentials = $request->validate([
                'nik_or_hp'   => 'required|string',
                'password'    => 'required|string',
                'force_login' => 'sometimes|boolean',
            ]);

            $user = User::where('nik', $credentials['nik_or_hp'])
                ->orWhere('no_hp', $credentials['nik_or_hp'])
                ->orWhere('email', $credentials['nik_or_hp'])
                ->first();

            if (!$user || !Hash::check($credentials['password'], $user->password)) {
                return response()->json([
                    'message' => 'NIK/No HP/Email atau password salah'
                ], 401);
            }

            if ($user->is_active === false) {
                return response()->json([
                    'message' => 'Akun Anda sedang dinonaktifkan. Silakan hubungi admin desa.'
                ], 403);
            }

            // Batasi 1 akun 1 perangkat
            $forceLogin = $request->input('force_login', false);
            
            if ($user->tokens()->count() > 0) {
                if (!$forceLogin) {
                    return response()->json([
                        'message' => 'Akun sedang digunakan di perangkat lain.',
                        'requires_force_login' => true
                    ], 403);
                } else {
                    // Hapus token lama (logout perangkat lain secara paksa)
                    $user->tokens()->delete();
                }
            }

            $token = $user->createToken('auth_token')->plainTextToken;

            return response()->json([
                'message' => 'Login berhasil',
                'token'   => $token,
                'role'    => $user->role,
                'user'    => $this->userPayload($user),
            ]);
        } catch (\Throwable $e) {
            $friendly = $this->friendlyDbError($e);

            $payload = [
                'message' => $friendly ?? 'Terjadi kesalahan server',
            ];

            if (config('app.debug') && !$friendly) {
                $payload['error'] = $e->getMessage();
            }

            return response()->json($payload, 500);
        }
    }

    // Logout
    public function logout(Request $request)
    {
        $request->user()->update(['fcm_token' => null]);
        $request->user()->currentAccessToken()->delete();

        return response()->json(['message' => 'Logout berhasil']);
    }

    // Profil user yang sedang login
    public function me(Request $request)
    {
        $user = $request->user();
        return response()->json($this->userPayload($user));
    }

    // Update profil (name, no_hp, email)
    public function updateProfile(Request $request)
    {
        $user = $request->user();

        $request->validate([
            'name'   => 'sometimes|string|max:255',
            'no_hp'  => 'sometimes|string|unique:users,no_hp,' . $user->id,
            'email'  => 'sometimes|nullable|email|unique:users,email,' . $user->id,
        ]);

        $user->update($request->only(['name', 'no_hp', 'email']));

        return response()->json([
            'message' => 'Profil berhasil diperbarui',
            'user' => $this->userPayload($user),
        ]);
    }

    public function forgotPassword(Request $request)
    {
        $request->validate([
            'identifier' => 'required|string',
            'no_hp' => 'required|string',
            'password' => 'required|string|min:6|confirmed',
        ]);

        $user = User::where(function ($query) use ($request) {
                $query->where('nik', $request->identifier)
                    ->orWhere('email', $request->identifier)
                    ->orWhere('no_hp', $request->identifier);
            })
            ->where('no_hp', $request->no_hp)
            ->first();

        if (!$user) {
            return response()->json([
                'message' => 'Data akun tidak cocok. Pastikan NIK/Email/No HP dan nomor HP terdaftar benar.'
            ], 404);
        }

        $user->update([
            'password' => Hash::make($request->password),
        ]);

        return response()->json([
            'message' => 'Password berhasil direset. Silakan login dengan password baru.'
        ]);
    }

    public function updateProfilePhoto(Request $request)
    {
        $request->validate([
            'profile_photo' => 'required|image|mimes:jpeg,png,jpg|max:2048',
        ]);

        $user = $request->user();

        if ($user->profile_photo && Storage::disk('public')->exists($user->profile_photo)) {
            Storage::disk('public')->delete($user->profile_photo);
        }

        $file = $request->file('profile_photo');
        $filename = time() . '_' . $file->getClientOriginalName();
        $path = $file->storeAs('profile_photos', $filename, 'public');

        $user->update(['profile_photo' => $path]);

        return response()->json([
            'message' => 'Foto profil berhasil diperbarui',
            'user' => $this->userPayload($user->fresh()),
        ]);
    }

    // Ubah password
    public function changePassword(Request $request)
    {
        $request->validate([
            'current_password' => 'required|string',
            'new_password'     => 'required|string|min:6|confirmed',
        ]);

        $user = $request->user();

        if (!Hash::check($request->current_password, $user->password)) {
            return response()->json(['message' => 'Password lama tidak sesuai'], 422);
        }

        $user->update(['password' => Hash::make($request->new_password)]);

        return response()->json(['message' => 'Password berhasil diubah']);
    }

    public function updateFcmToken(Request $request)
    {
        $request->validate([
            'fcm_token' => 'required|string',
        ]);

        $user = $request->user();
        $user->update([
            'fcm_token' => $request->fcm_token,
        ]);

        return response()->json([
            'message' => 'FCM token berhasil disimpan',
        ]);
    }
}
