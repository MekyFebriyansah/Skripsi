<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('laporan_keluhan', function (Blueprint $table) {
            if (!Schema::hasColumn('laporan_keluhan', 'foto_pengaduan_at')) {
                $table->timestamp('foto_pengaduan_at')->nullable()->after('foto_pengaduan');
            }
            if (!Schema::hasColumn('laporan_keluhan', 'foto_bukti_at')) {
                $table->timestamp('foto_bukti_at')->nullable()->after('foto_bukti');
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('laporan_keluhan', function (Blueprint $table) {
            if (Schema::hasColumn('laporan_keluhan', 'foto_pengaduan_at')) {
                $table->dropColumn('foto_pengaduan_at');
            }
            if (Schema::hasColumn('laporan_keluhan', 'foto_bukti_at')) {
                $table->dropColumn('foto_bukti_at');
            }
        });
    }
};
