<?php

namespace App\Http\Controllers;

use App\Models\LaporanKeluhan;
use App\Models\KategoriKeluhan;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Storage;

class LaporanController extends Controller
{
    // ================== MASYARAKAT ==================
    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'judul'        => 'required|string|max:255',
            'kategori_id'  => 'required|exists:kategori_keluhan,id',
            'deskripsi'    => 'required|string',
            'latitude'     => 'nullable|numeric',
            'longitude'    => 'nullable|numeric',
            'foto_pengaduan' => 'nullable|image|mimes:jpeg,png,jpg|max:2048',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'message' => 'Validasi gagal',
                'errors'  => $validator->errors()
            ], 422);
        }

        $kategori = KategoriKeluhan::findOrFail($request->kategori_id);

        $data = [
            'user_id'     => Auth::id(),
            'kategori_id' => $request->kategori_id,
            'kategori'    => $kategori->nama_kategori,
            'judul'       => $request->judul,
            'deskripsi'   => $request->deskripsi,
            'latitude'    => $request->latitude,
            'longitude'   => $request->longitude,
            'status'      => 'Belum Ditangani',
        ];

        if ($request->hasFile('foto_pengaduan')) {
            $file = $request->file('foto_pengaduan');
            $filename = time() . '_' . $file->getClientOriginalName();
            $data['foto_pengaduan'] = $file->storeAs('laporan_pengaduan', $filename, 'public');
            $data['foto_pengaduan_at'] = now();
        }

        $laporan = LaporanKeluhan::create($data);

        return response()->json([
            'message' => 'Pengaduan berhasil dikirim',
            'data'    => $laporan->load('kategori')
        ], 201);
    }

    public function index(Request $request)
    {
        $laporans = LaporanKeluhan::where('user_id', Auth::id())
            ->with('kategori')
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json($laporans);
    }

    // ================== ADMIN & SEKRETARIS ==================
    public function allLaporan(Request $request)
    {
        $laporans = LaporanKeluhan::with(['user', 'kategori'])
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json($laporans);
    }

    public function update(Request $request, $id)
    {
        $laporan = LaporanKeluhan::findOrFail($id);

        $validator = Validator::make($request->all(), [
            'status'      => 'required|in:Belum Ditangani,Sedang Diproses,Selesai',
            'tanggapan'   => 'nullable|string',
            'foto_proses' => 'nullable|image|mimes:jpeg,png,jpg|max:2048',
            'foto_bukti'  => 'nullable|image|mimes:jpeg,png,jpg|max:2048',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        if ($request->status === 'Sedang Diproses' &&
            !$request->hasFile('foto_proses') &&
            empty($laporan->foto_proses)) {
            return response()->json([
                'message' => 'Foto bukti proses wajib diunggah saat status Sedang Diproses.'
            ], 422);
        }

        if ($request->status === 'Selesai' &&
            !$request->hasFile('foto_bukti') &&
            empty($laporan->foto_bukti)) {
            return response()->json([
                'message' => 'Foto bukti penyelesaian wajib diunggah saat status Selesai.'
            ], 422);
        }

        $data = [
            'status'    => $request->status,
            'tanggapan' => $request->tanggapan,
        ];

        if ($request->status === 'Sedang Diproses' && $request->hasFile('foto_proses')) {
            if ($laporan->foto_proses && Storage::disk('public')->exists($laporan->foto_proses)) {
                Storage::disk('public')->delete($laporan->foto_proses);
            }

            $file = $request->file('foto_proses');
            $filename = time() . '_' . $file->getClientOriginalName();
            $path = $file->storeAs('laporan_proses', $filename, 'public');
            $data['foto_proses'] = $path;
            $data['foto_proses_at'] = now();
        }

        if ($request->status === 'Selesai' && $request->hasFile('foto_bukti')) {
            if ($laporan->foto_bukti && Storage::disk('public')->exists($laporan->foto_bukti)) {
                Storage::disk('public')->delete($laporan->foto_bukti);
            }

            $file = $request->file('foto_bukti');
            $filename = time() . '_' . $file->getClientOriginalName();
            $path = $file->storeAs('laporan_bukti', $filename, 'public');
            $data['foto_bukti'] = $path;
            $data['foto_bukti_at'] = now();
        }

        $laporan->update($data);

        return response()->json([
            'message' => 'Laporan berhasil diperbarui',
            'data'    => $laporan->load(['user', 'kategori'])
        ]);
    }
}