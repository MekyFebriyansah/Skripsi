<?php

namespace App\Models;

use Illuminate\Contracts\Auth\MustVerifyEmail;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable;

    protected $fillable = [
        'name',
        'nik',
        'no_hp',
        'email',
        'password',
        'role',
        'is_active',
        'fcm_token',
        'profile_photo',
    ];

    protected $hidden = [
        'password',
        'remember_token',
    ];

    protected $casts = [
        'email_verified_at' => 'datetime',
        'password' => 'hashed',
        'is_active' => 'boolean',
    ];

    // Relationship
    public function laporanKeluhan()
    {
        return $this->hasMany(LaporanKeluhan::class);
    }

    // Helper untuk cek role
    public function isAdmin()
    {
        return $this->role === 'admin';
    }

    public function isSekretaris()
    {
        return $this->role === 'sekretaris';
    }

    public function isKepalaDesa()
    {
        return $this->role === 'kepala_desa';
    }

    public function isPemerintah()
    {
        return in_array($this->role, ['sekretaris', 'kepala_desa']);
    }

    public function isMasyarakat()
    {
        return $this->role === 'masyarakat' || $this->role === null;
    }
}
