<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class PesanLaporan extends Model
{
    use HasFactory;

    protected $table = 'pesan_laporan';

    protected $fillable = [
        'laporan_id',
        'user_id',
        'pesan',
        'pengirim_role',
        'is_read',
    ];

    protected $casts = [
        'is_read' => 'boolean',
    ];

    // Relationships
    public function laporan()
    {
        return $this->belongsTo(LaporanKeluhan::class, 'laporan_id');
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
