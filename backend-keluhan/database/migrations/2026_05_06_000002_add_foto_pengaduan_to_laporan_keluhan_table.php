<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('laporan_keluhan', function (Blueprint $table) {
            if (!Schema::hasColumn('laporan_keluhan', 'foto_pengaduan')) {
                $table->string('foto_pengaduan')->nullable()->after('tanggapan');
            }
        });
    }

    public function down(): void
    {
        Schema::table('laporan_keluhan', function (Blueprint $table) {
            if (Schema::hasColumn('laporan_keluhan', 'foto_pengaduan')) {
                $table->dropColumn('foto_pengaduan');
            }
        });
    }
};
