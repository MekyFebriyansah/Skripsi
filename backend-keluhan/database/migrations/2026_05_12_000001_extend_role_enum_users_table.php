<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // Ubah kolom role menjadi string fleksibel agar bisa menampung role baru
        // (kepala_desa). Tetap default 'masyarakat'.
        $driver = DB::getDriverName();

        if ($driver === 'mysql') {
            DB::statement(
                "ALTER TABLE `users` MODIFY `role` ENUM('masyarakat','admin','sekretaris','kepala_desa') NOT NULL DEFAULT 'masyarakat'"
            );
        } else {
            // Fallback untuk pgsql/sqlite: ubah jadi string
            Schema::table('users', function ($table) {
                $table->string('role', 30)->default('masyarakat')->change();
            });
        }
    }

    public function down(): void
    {
        $driver = DB::getDriverName();

        if ($driver === 'mysql') {
            // Pastikan tidak ada user yang masih bernilai kepala_desa sebelum rollback
            DB::table('users')->where('role', 'kepala_desa')->update(['role' => 'sekretaris']);
            DB::statement(
                "ALTER TABLE `users` MODIFY `role` ENUM('masyarakat','admin','sekretaris') NOT NULL DEFAULT 'masyarakat'"
            );
        }
    }
};
