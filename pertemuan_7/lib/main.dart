import 'package:flutter/material.dart';
import 'api_client.dart';

void main() {
  runApp(const MyApp());
}

// === MODEL ===
class Catatan {
  final int? id;
  final String judul;
  final String isi;
  final String kategori;
  final DateTime dibuatPada;

  Catatan({
    this.id,
    required this.judul,
    required this.isi,
    required this.kategori,
    required this.dibuatPada,
  });

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'judul': judul,
        'isi': isi,
        'kategori': kategori,
        'dibuat_pada': dibuatPada.toUtc().toIso8601String(),
      };

  static Catatan fromJson(Map<String, dynamic> m) => Catatan(
        id: m['id'] as int?,
        judul: m['judul'] as String,
        isi: m['isi'] as String,
        kategori: m['kategori'] as String,
        dibuatPada: DateTime.parse(m['dibuat_pada'] as String),
      );

  Catatan copyWith({
    String? judul,
    String? isi,
    String? kategori,
  }) =>
      Catatan(
        id: id,
        judul: judul ?? this.judul,
        isi: isi ?? this.isi,
        kategori: kategori ?? this.kategori,
        dibuatPada: dibuatPada,
      );
}

// === APP ROOT ===
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Catatan Mahasiswa',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomePage(),
      },

      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/form':
            final arg = settings.arguments;
            return MaterialPageRoute(
              builder: (_) => CatatanFormPage(initial: arg as Catatan?),
            );
          case '/detail':
            final c = settings.arguments as Catatan;
            return MaterialPageRoute(
              builder: (_) => DetailCatatanPage(catatan: c),
            );
        }
        return null;
      },
    );
  }
}

// === HOME PAGE ===
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _filterKategori = 'Semua';
  late Future<List<Catatan>> _futureCatatan;

  @override
  void initState() {
    super.initState();
    _muatUlang();
  }

  void _muatUlang() {
    setState(() {
      _futureCatatan = ApiClient.instance.getAll();
    });
  }

  Future<void> _bukaForm({Catatan? initial}) async {
    await Navigator.pushNamed(context, '/form', arguments: initial);
    _muatUlang();
  }

  Future<void> _bukaDetail(Catatan c) async {
    await Navigator.pushNamed(context, '/detail', arguments: c);
    _muatUlang();
  }

  Future<void> _konfirmasiHapus(Catatan c) async {
    final yakin = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus catatan?'),
        content: Text('"${c.judul}" akan dihapus permanen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (yakin == true) {
      try {
        await ApiClient.instance.delete(c.id!);
        if (!mounted) return;
        _muatUlang();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"${c.judul}" dihapus')),
        );
      } on ApiException catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghapus: ${e.message}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catatan Mahasiswa'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: DropdownButton<String>(
              value: _filterKategori,
              icon: const Icon(Icons.filter_list),
              underline: const SizedBox(),
              items: const ['Semua', 'Kuliah', 'Tugas', 'Pribadi', 'Lainnya']
                  .map((kategori) => DropdownMenuItem(
                value: kategori,
                child: Text(kategori),
              ))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _filterKategori = v);
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _muatUlang,
          ),
        ],
      ),
      body: FutureBuilder<List<Catatan>>(
        future: _futureCatatan,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            final e = snapshot.error;
            final pesan = e is ApiException ? e.message : 'Terjadi kesalahan: $e';
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 8),
                  Text(pesan, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 12),
                  FilledButton(onPressed: _muatUlang, child: const Text('Coba lagi')),
                ],
              ),
            );
          }

          final data = snapshot.data ?? [];
          final listDitampilkan = _filterKategori == 'Semua'
              ? data
              : data.where((c) => c.kategori == _filterKategori).toList();

          if (listDitampilkan.isEmpty) {
            return const Center(child: Text('Tidak ada catatan dalam kategori ini'));
          }

          return ListView.builder(
            itemCount: listDitampilkan.length,
            padding: const EdgeInsets.all(12),
            itemBuilder: (context, i) {
              final c = listDitampilkan[i];

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(c.judul, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                      '${c.kategori} • ${c.dibuatPada.day}/${c.dibuatPada.month}/${c.dibuatPada.year}'),

                  // LANGKAH 7: DUA TOMBOL DI TRAILING (EDIT & DELETE)
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => _bukaForm(initial: c),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => _konfirmasiHapus(c),
                      ),
                    ],
                  ),
                  onTap: () => _bukaDetail(c),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _bukaForm(),
        icon: const Icon(Icons.add),
        label: const Text('Tambah'),
      ),
    );
  }
}

// === CATATAN FORM PAGE ===
class CatatanFormPage extends StatefulWidget {
  final Catatan? initial;
  const CatatanFormPage({super.key, this.initial});

  @override
  State<CatatanFormPage> createState() => _CatatanFormPageState();
}

class _CatatanFormPageState extends State<CatatanFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _judulCtrl;
  late final TextEditingController _isiCtrl;

  late String _kategori;
  late DateTime _tanggalTerpilih;

  final _kategoriOpsi = const ['Kuliah', 'Tugas', 'Pribadi', 'Lainnya'];
  bool _menyimpan = false;

  bool get _isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();

    _judulCtrl = TextEditingController(text: widget.initial?.judul ?? '');
    _isiCtrl = TextEditingController(text: widget.initial?.isi ?? '');
    _kategori = widget.initial?.kategori ?? 'Kuliah';
    _tanggalTerpilih = widget.initial?.dibuatPada ?? DateTime.now();
  }

  @override
  void dispose() {
    _judulCtrl.dispose();
    _isiCtrl.dispose();
    super.dispose();
  }

  Future<void> _pilihTanggal(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _tanggalTerpilih,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _tanggalTerpilih) {
      setState(() {
        _tanggalTerpilih = picked;
      });
    }
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _menyimpan = true);

    try {
      if (_isEdit) {
        final updated = widget.initial!.copyWith(
          judul: _judulCtrl.text.trim(),
          isi: _isiCtrl.text.trim(),
          kategori: _kategori,
        );
        await ApiClient.instance.update(updated);
      } else {
        final baru = Catatan(
          judul: _judulCtrl.text.trim(),
          isi: _isiCtrl.text.trim(),
          kategori: _kategori,
          dibuatPada: _tanggalTerpilih,
        );
        await ApiClient.instance.insert(baru);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_isEdit ? 'Catatan diperbarui' : 'Catatan ditambahkan'),
      ));
      Navigator.pop(context);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _menyimpan = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan: ${e.message}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit Catatan' : 'Tambah Catatan')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _judulCtrl,
              decoration: const InputDecoration(
                labelText: 'Judul',
                prefixIcon: Icon(Icons.title),
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Judul wajib diisi';
                if (v.trim().length < 3) return 'Minimal 3 karakter';
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _kategori,
              decoration: const InputDecoration(
                labelText: 'Kategori',
                prefixIcon: Icon(Icons.category),
                border: OutlineInputBorder(),
              ),
              items: _kategoriOpsi
                  .map((k) => DropdownMenuItem(value: k, child: Text(k)))
                  .toList(),
              onChanged: (v) => setState(() => _kategori = v!),
            ),
            const SizedBox(height: 16),
            Card(
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: Colors.grey.shade600.withOpacity(0.6)),
                borderRadius: BorderRadius.circular(4),
              ),
              child: ListTile(
                leading: const Icon(Icons.calendar_month, color: Colors.indigo),
                title: const Text('Tanggal Catatan'),
                subtitle: Text('${_tanggalTerpilih.day}/${_tanggalTerpilih.month}/${_tanggalTerpilih.year}'),
                trailing: TextButton(
                  onPressed: () => _pilihTanggal(context),
                  child: const Text('Pilih'),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _isiCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Isi',
                prefixIcon: Icon(Icons.notes),
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Isi wajib diisi' : null,
            ),
            const SizedBox(height: 24),
            _menyimpan
                ? const Center(child: CircularProgressIndicator())
                : FilledButton.icon(
              onPressed: _simpan,
              icon: const Icon(Icons.save),
              label: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }
}

// === DETAIL PAGE ===
class DetailCatatanPage extends StatelessWidget {
  final Catatan catatan;

  const DetailCatatanPage({
    super.key,
    required this.catatan,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Catatan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              // Menuju halaman form dan langsung menutup detail (Langkah 6.3)
              await Navigator.pushNamed(context, '/form', arguments: catatan);
              if (context.mounted) Navigator.pop(context);
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(catatan.judul,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Chip(label: Text(catatan.kategori)),
                const SizedBox(width: 8),
                Chip(
                    avatar: const Icon(Icons.calendar_today, size: 16),
                    label: Text(
                        '${catatan.dibuatPada.day}/${catatan.dibuatPada.month}/${catatan.dibuatPada.year}')),
              ],
            ),
            const Divider(height: 32),
            Text(catatan.isi, style: const TextStyle(fontSize: 16, height: 1.5)),
          ],
        ),
      ),
    );
  }
}