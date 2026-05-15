<?php

use App\Http\Controllers\AuthController;
use App\Http\Controllers\KategoriController;
use App\Http\Controllers\LaporanController;
use App\Http\Controllers\PesanController;
use App\Http\Controllers\UserController;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);
Route::post('/forgot-password', [AuthController::class, 'forgotPassword']);

Route::middleware('auth:sanctum')->group(function () {

    Route::post('/logout', [AuthController::class, 'logout']);
    Route::get('/me', [AuthController::class, 'me']);
    Route::post('/me/fcm-token', [AuthController::class, 'updateFcmToken']);
    Route::put('/me/profile', [AuthController::class, 'updateProfile']);
    Route::post('/me/profile-photo', [AuthController::class, 'updateProfilePhoto']);
    Route::put('/me/password', [AuthController::class, 'changePassword']);

    // Kategori (semua user yang login bisa lihat)
    Route::get('/kategori', [KategoriController::class, 'index']);

    // Laporan Masyarakat
    Route::post('/laporan', [LaporanController::class, 'store'])
         ->middleware('role:masyarakat');

    Route::get('/laporan/saya', [LaporanController::class, 'index'])
         ->middleware('role:masyarakat');

    // Admin, Sekretaris, Kepala Desa
    Route::middleware('role:admin,sekretaris,kepala_desa')->group(function () {
        Route::get('/laporan', [LaporanController::class, 'allLaporan']);
        Route::put('/laporan/{id}', [LaporanController::class, 'update']);
    });

    // Chat/Pesan Laporan (admin dan masyarakat yang terlibat)
    Route::get('/laporan/{laporanId}/pesan', [PesanController::class, 'index']);
    Route::post('/laporan/{laporanId}/pesan', [PesanController::class, 'store']);
    Route::get('/pesan/unread-count', [PesanController::class, 'unreadCount']);
    Route::get('/pesan/notifikasi', [PesanController::class, 'notifications']);

    // Admin only
    Route::middleware('role:admin')->group(function () {
        Route::post('/kategori', [KategoriController::class, 'store']);
        Route::delete('/kategori/{id}', [KategoriController::class, 'destroy']);
        Route::get('/users', [UserController::class, 'index']);
        Route::put('/users/{id}/toggle-status', [UserController::class, 'toggleStatus']);
    });
});