<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class LaporanKeluhan extends Model
{
    use HasFactory;

    protected $table = 'laporan_keluhan';

    protected $fillable = [
        'user_id',
        'kategori_id',           // ← Diubah jadi foreign key
        'kategori',
        'judul',
        'deskripsi',
        'deskripsi_terenkripsi',
        'latitude',
        'longitude',
        'status',
        'tanggapan',
        'foto_pengaduan',
        'foto_pengaduan_at',
        'foto_proses',
        'foto_proses_at',
        'foto_bukti',
        'foto_bukti_at',
    ];

    protected $casts = [
        'latitude' => 'decimal:8',
        'longitude' => 'decimal:8',
        'foto_pengaduan_at' => 'datetime',
        'foto_proses_at' => 'datetime',
        'foto_bukti_at' => 'datetime',
    ];

    // Relationships
    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function kategori()
    {
        return $this->belongsTo(KategoriKeluhan::class, 'kategori_id');
    }

    public function pesanLaporan()
    {
        return $this->hasMany(PesanLaporan::class, 'laporan_id');
    }
}