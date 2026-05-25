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

  Catatan({
    required this.judul,
    required this.isi,
    required this.kategori,
    required this.dibuatPada,
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
          // Menerima argumen Map jika dalam mode edit
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
  final List<Catatan> _catatan = [
    Catatan(
      judul: 'Belajar Flutter',
      isi: 'Mempelajari Stateful Widget, Form, dan Navigation.',
      kategori: 'Kuliah',
      dibuatPada: DateTime.now(),
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

  Future<void> _bukaDetail(Catatan c, int index) async {
    final hasil = await Navigator.pushNamed(
        context,
        '/detail',
        arguments: {'catatan': c, 'index': index}
    );

    // Menangkap kembalian dari halaman detail jika user melakukan edit
    if (hasil is Map<String, dynamic> && hasil['mode'] == 'edit') {
      setState(() {
        _catatan[hasil['index']] = hasil['catatan'];
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Catatan diperbarui')),
      );
    }
  }

  void _hapusCatatan(int index) {
    setState(() {
      _catatan.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Catatan Mahasiswa')),
      body: _catatan.isEmpty
          ? const Center(child: Text('Belum ada catatan'))
          : ListView.builder(
        itemCount: _catatan.length,
        itemBuilder: (context, i) {
          final c = _catatan[i];
          return ListTile(
            title: Text(c.judul),
            subtitle: Text(c.kategori),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _hapusCatatan(i),
            ),
            onTap: () => _bukaDetail(c, i),
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

// === TAMBAH / EDIT PAGE ===
class TambahCatatanPage extends StatefulWidget {
  final Catatan? catatanLama;
  final int? index;

  // Jika catatanLama tidak null, berarti halaman ini bertindak sebagai form Edit
  const TambahCatatanPage({super.key, this.catatanLama, this.index});

  @override
  State<TambahCatatanPage> createState() => _TambahCatatanPageState();
}

class _TambahCatatanPageState extends State<TambahCatatanPage> {
  final _formKey = GlobalKey<FormState>();
  final _judulCtrl = TextEditingController();
  final _isiCtrl = TextEditingController();

  String _kategori = 'Kuliah';
  final _kategoriOpsi = const ['Kuliah', 'Tugas', 'Pribadi', 'Lainnya'];

  @override
  void initState() {
    super.initState();
    // Mengisi form dengan data lama jika dalam mode edit
    if (widget.catatanLama != null) {
      _judulCtrl.text = widget.catatanLama!.judul;
      _isiCtrl.text = widget.catatanLama!.isi;
      _kategori = widget.catatanLama!.kategori;
    }
  }

  @override
  void dispose() {
    _judulCtrl.dispose();
    _isiCtrl.dispose();
    super.dispose();
  }

  void _simpan() {
    if (!_formKey.currentState!.validate()) return;

    final catatanBaru = Catatan(
      judul: _judulCtrl.text.trim(),
      isi: _isiCtrl.text.trim(),
      kategori: _kategori,
      // Tetap gunakan tanggal lama jika diedit, atau tanggal baru jika ditambah
      dibuatPada: widget.catatanLama?.dibuatPada ?? DateTime.now(),
    );

    // Mengirim balik Map agar Home tahu apakah ini data baru atau update
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
            TextFormField(
              controller: _isiCtrl,
              maxLines: 5,
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
              // Menavigasi ke form edit dan meneruskan datanya
              final hasil = await Navigator.pushNamed(
                  context,
                  '/tambah',
                  arguments: {'catatan': catatan, 'index': index}
              );

              // Jika mendapat kembalian hasil edit, langsung pop ke Home
              // dengan instruksi mode 'edit'
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
            Chip(label: Text(catatan.kategori)),
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