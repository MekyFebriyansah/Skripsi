<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up()
    {
        Schema::table('users', function (Blueprint $table) {
            $table->string('nik')->unique()->nullable()->after('name');
            $table->string('no_hp')->unique()->nullable()->after('nik');
            $table->enum('role', ['masyarakat', 'admin', 'sekretaris'])
                ->default('masyarakat')
                ->after('no_hp');
        });
    }

    public function down()
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn(['nik', 'no_hp', 'role']);
        });
    }
};
