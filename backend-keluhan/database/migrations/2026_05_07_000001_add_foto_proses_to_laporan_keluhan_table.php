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
            if (!Schema::hasColumn('laporan_keluhan', 'foto_proses')) {
                $table->string('foto_proses')->nullable()->after('foto_pengaduan_at');
            }

            if (!Schema::hasColumn('laporan_keluhan', 'foto_proses_at')) {
                $table->timestamp('foto_proses_at')->nullable()->after('foto_proses');
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('laporan_keluhan', function (Blueprint $table) {
            if (Schema::hasColumn('laporan_keluhan', 'foto_proses_at')) {
                $table->dropColumn('foto_proses_at');
            }

            if (Schema::hasColumn('laporan_keluhan', 'foto_proses')) {
                $table->dropColumn('foto_proses');
            }
        });
    }
};
