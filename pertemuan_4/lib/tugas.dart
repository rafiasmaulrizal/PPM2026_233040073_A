import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

// === MODEL ===
class Catatan {
  final String judul;
  final String isi;
  final String kategori;
  final DateTime dibuatPada;
  final String emailPengirim;

  Catatan({
    required this.judul,
    required this.isi,
    required this.kategori,
    required this.dibuatPada,
    required this.emailPengirim,
  });
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
          case '/tambah':
            final args = settings.arguments as Map<String, dynamic>?;
            return MaterialPageRoute(
              builder: (_) => TambahCatatanPage(
                catatanLama: args?['catatan'],
                index: args?['index'],
              ),
            );
          case '/detail':
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => DetailCatatanPage(
                catatan: args['catatan'],
                index: args['index'],
              ),
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

  final List<Catatan> _catatan = [
    Catatan(
      judul: 'Belajar Flutter',
      isi: 'Mempelajari Stateful Widget, Form, dan Navigation.',
      kategori: 'Kuliah',
      dibuatPada: DateTime.now(),
      emailPengirim: 'peserta@unpas.ac.id',
    ),
  ];

  Future<void> _bukaFormCatatan() async {
    final hasil = await Navigator.pushNamed(context, '/tambah');

    if (hasil is Map<String, dynamic>) {
      setState(() => _catatan.add(hasil['catatan']));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Catatan "${hasil['catatan'].judul}" ditambahkan')),
      );
    }
  }

  Future<void> _bukaDetail(Catatan c, int masterIndex) async {
    final hasil = await Navigator.pushNamed(
        context,
        '/detail',
        arguments: {'catatan': c, 'index': masterIndex}
    );

    if (hasil is Map<String, dynamic> && hasil['mode'] == 'edit') {
      setState(() {
        _catatan[hasil['index']] = hasil['catatan'];
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Catatan berhasil diperbarui')),
      );
    }
  }

  void _hapusCatatan(int masterIndex) {
    setState(() {
      _catatan.removeAt(masterIndex);
    });
  }

  @override
  Widget build(BuildContext context) {
    final listDitampilkan = _filterKategori == 'Semua'
        ? _catatan
        : _catatan.where((c) => c.kategori == _filterKategori).toList();

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
        ],
      ),
      body: listDitampilkan.isEmpty
          ? const Center(child: Text('Tidak ada catatan dalam kategori ini'))
          : ListView.builder(
        itemCount: listDitampilkan.length,
        itemBuilder: (context, i) {
          final c = listDitampilkan[i];

          final masterIndex = _catatan.indexOf(c);

          return ListTile(
            title: Text(c.judul),
            subtitle: Text('${c.kategori} • ${c.dibuatPada.day}/${c.dibuatPada.month}/${c.dibuatPada.year}'),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _hapusCatatan(masterIndex),
            ),
            onTap: () => _bukaDetail(c, masterIndex),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _bukaFormCatatan,
        child: const Icon(Icons.add),
      ),
    );
  }
}

// === TAMBAH EDIT PAGE ===
class TambahCatatanPage extends StatefulWidget {
  final Catatan? catatanLama;
  final int? index;

  const TambahCatatanPage({super.key, this.catatanLama, this.index});

  @override
  State<TambahCatatanPage> createState() => _TambahCatatanPageState();
}

class _TambahCatatanPageState extends State<TambahCatatanPage> {
  final _formKey = GlobalKey<FormState>();
  final _judulCtrl = TextEditingController();
  final _isiCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  String _kategori = 'Kuliah';
  final _kategoriOpsi = const ['Kuliah', 'Tugas', 'Pribadi', 'Lainnya'];

  DateTime _tanggalTerpilih = DateTime.now();

  @override
  void initState() {
    super.initState();
    if (widget.catatanLama != null) {
      _judulCtrl.text = widget.catatanLama!.judul;
      _isiCtrl.text = widget.catatanLama!.isi;
      _kategori = widget.catatanLama!.kategori;
      _emailCtrl.text = widget.catatanLama!.emailPengirim;
      _tanggalTerpilih = widget.catatanLama!.dibuatPada;
    }
  }

  @override
  void dispose() {
    _judulCtrl.dispose();
    _isiCtrl.dispose();
    _emailCtrl.dispose();
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

  void _simpan() {
    if (!_formKey.currentState!.validate()) return;

    final catatanBaru = Catatan(
      judul: _judulCtrl.text.trim(),
      isi: _isiCtrl.text.trim(),
      kategori: _kategori,
      dibuatPada: _tanggalTerpilih,
      emailPengirim: _emailCtrl.text.trim(),
    );

    Navigator.pop(context, {
      'catatan': catatanBaru,
      'index': widget.index,
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.catatanLama != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Catatan' : 'Tambah Catatan')),
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

            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email Pengirim',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Email wajib diisi';

                final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                if (!emailRegex.hasMatch(v.trim())) {
                  return 'Format email tidak valid (contoh: user@email.com)';
                }
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
            FilledButton.icon(
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
  final int index;

  const DetailCatatanPage({
    super.key,
    required this.catatan,
    required this.index,
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
              final hasil = await Navigator.pushNamed(
                  context,
                  '/tambah',
                  arguments: {'catatan': catatan, 'index': index}
              );

              if (hasil != null && context.mounted) {
                Navigator.pop(context, {
                  'mode': 'edit',
                  'catatan': (hasil as Map)['catatan'],
                  'index': index
                });
              }
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                catatan.judul,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Chip(label: Text(catatan.kategori)),
                const SizedBox(width: 8),
                Chip(
                    avatar: const Icon(Icons.calendar_today, size: 16),
                    label: Text('${catatan.dibuatPada.day}/${catatan.dibuatPada.month}/${catatan.dibuatPada.year}')
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.email, size: 18, color: Colors.grey),
                const SizedBox(width: 8),
                Text(catatan.emailPengirim, style: const TextStyle(color: Colors.grey)),
              ],
            ),
            const Divider(height: 32),
            Text(
                catatan.isi,
                style: const TextStyle(fontSize: 16, height: 1.5)
            ),
          ],
        ),
      ),
    );
  }
}