<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class KategoriKeluhan extends Model
{
    use HasFactory;

    protected $table = 'kategori_keluhan';

    protected $fillable = [
        'nama_kategori',
        'deskripsi',
    ];

    public function laporanKeluhan()
    {
        return $this->hasMany(LaporanKeluhan::class, 'kategori_id');
    }
}
