import 'main.dart' show Catatan;

class DbHelper {
  DbHelper._();
  static final DbHelper instance = DbHelper._();

  final List<Catatan> _items = [];

  Future<List<Catatan>> getAll() async {
    return List.of(_items.reversed);
  }

  Future<int> insert(Catatan c) async {
    final id = _items.isEmpty ? 1 : (_items.last.id ?? _items.length) + 1;
    _items.add(Catatan(
      id: id,
      judul: c.judul,
      isi: c.isi,
      kategori: c.kategori,
      dibuatPada: c.dibuatPada,
      emailPengirim: c.emailPengirim,
    ));
    return id;
  }

  Future<int> update(Catatan c) async {
    final index = _items.indexWhere((item) => item.id == c.id);
    if (index == -1) {
      throw StateError('Catatan tidak ditemukan');
    }
    _items[index] = c;
    return 1;
  }

  Future<int> delete(int id) async {
    final index = _items.indexWhere((item) => item.id == id);
    if (index == -1) return 0;
    _items.removeAt(index);
    return 1;
  }
}
