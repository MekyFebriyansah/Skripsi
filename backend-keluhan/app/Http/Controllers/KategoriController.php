<?php

namespace App\Http\Controllers;

use App\Models\KategoriKeluhan;
use Illuminate\Http\Request;

class KategoriController extends Controller
{
    public function index()
    {
        return response()->json(KategoriKeluhan::all());
    }

    public function store(Request $request)
    {
        $request->validate(['nama_kategori' => 'required|string|unique:kategori_keluhan']);

        $kategori = KategoriKeluhan::create($request->only('nama_kategori', 'deskripsi'));

        return response()->json($kategori, 201);
    }

    public function destroy($id)
    {
        $kategori = KategoriKeluhan::findOrFail($id);
        $kategori->delete();

        return response()->json(['message' => 'Kategori berhasil dihapus']);
    }
}