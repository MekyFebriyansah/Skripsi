<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        $driver = DB::getDriverName();

        if ($driver === 'mysql') {
            DB::statement(
                "ALTER TABLE `pesan_laporan` MODIFY `pengirim_role` ENUM('admin','masyarakat','sekretaris','kepala_desa') NOT NULL"
            );
        } else {
            Schema::table('pesan_laporan', function ($table) {
                $table->string('pengirim_role', 30)->change();
            });
        }
    }

    public function down(): void
    {
        $driver = DB::getDriverName();

        if ($driver === 'mysql') {
            DB::statement(
                "ALTER TABLE `pesan_laporan` MODIFY `pengirim_role` ENUM('admin','masyarakat') NOT NULL"
            );
        }
    }
};
