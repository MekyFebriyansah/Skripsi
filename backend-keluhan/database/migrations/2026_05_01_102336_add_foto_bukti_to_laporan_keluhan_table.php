<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::table('laporan_keluhan', function (Blueprint $table) {
            $table->string('foto_bukti')->nullable()->after('tanggapan');
        });
    }

    public function down(): void
    {
        Schema::table('laporan_keluhan', function (Blueprint $table) {
            $table->dropColumn('foto_bukti');
        });
    }
};