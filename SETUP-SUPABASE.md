# Setup Supabase — Stok Sparepart Gudang Pengadaan

Aplikasi web: https://rinaldiwijaya3-boop.github.io/stok-sparepart-gudang-pengadaan/

## 1. Jalankan SQL keamanan
1. Buka https://supabase.com/dashboard/project/hvjbohczvlkjnhvghbkw
2. Pilih **SQL Editor** → **New query**.
3. Buka file `supabase-setup.sql` di repository ini, salin seluruh isi, lalu jalankan di SQL Editor.
4. Pastikan query selesai tanpa error.

Aplikasi memakai Project URL `https://hvjbohczvlkjnhvghbkw.supabase.co` dan publishable key di frontend. Jangan pernah menaruh secret/service_role key di repository.

## 2. Buat akun admin pertama
1. Di Supabase buka **Authentication → Users → Add user**.
2. Masukkan email admin dan buat password. Gunakan opsi konfirmasi user jika tersedia.
3. Buka **SQL Editor** dan jalankan query ini dengan email admin yang persis sama:

```sql
update public.profiles
set role = 'admin'
where lower(email) = lower('EMAIL_ADMIN_ANDA');
```

Ganti `EMAIL_ADMIN_ANDA` dengan email admin. Periksa hasilnya:

```sql
select id, email, role from public.profiles;
```

Akun yang dibuat setelah trigger SQL aktif otomatis mendapat role `viewer`.

## 3. Buat akun viewer
Admin/penanggung jawab dapat menambahkan akun lewat **Authentication → Users → Add user**. Setiap akun baru mendapat role `viewer`. Jangan promosikan role tanpa persetujuan pemilik gudang.

## 4. Cara kerja
- Admin dapat mencatat barang masuk/keluar, mengubah master, lokasi/kapasitas, import dan menghapus riwayat.
- Viewer dapat melihat dashboard, persediaan, riwayat transaksi, lokasi, stok menipis, dan ekspor data, tetapi tidak dapat menyimpan perubahan.
- Kebijakan Row Level Security (RLS) di database mengizinkan penulisan hanya untuk admin. Menyembunyikan tombol di halaman bukan satu-satunya lapisan keamanan.

## 5. Migrasi data lama
Pada login admin pertama, aplikasi akan mencoba menggunakan data lama dari `localStorage` di browser admin untuk menginisialisasi database jika belum ada data bersama. Pastikan login pertama admin dilakukan dari browser/perangkat yang memiliki data lama yang benar. Jika data lama tidak tersedia di browser tersebut, database dimulai dari data master bawaan aplikasi. Jangan login viewer terlebih dahulu sebelum admin menginisialisasi database.

## 6. Jika login gagal
- Pastikan SQL di atas sudah dijalankan.
- Pastikan akun ada di **Authentication → Users**.
- Pastikan profil admin sudah dinaikkan menjadi `admin` lewat SQL.
- Setelah perubahan GitHub Pages, tunggu deployment selesai lalu refresh browser.
