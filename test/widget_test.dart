import 'package:flutter_test/flutter_test.dart';
import 'package:uts_mobile/main.dart';

void main() {
  test('QueueCubit: ambil, panggil, tidak melebihi total, reset', () {
    final q = QueueCubit();
    q.callNext();
    expect(q.state, (total: 0, served: 0));
    q.takeNumber();
    q.takeNumber();
    q.callNext();
    expect(q.state, (total: 2, served: 1));
    q.callNext();
    q.callNext();
    expect(q.state.served, 2);
    q.takeNumber();
    q.cancel();
    q.cancel(); // tidak boleh membatalkan nomor yang sudah dilayani
    expect(q.state, (total: 2, served: 2));
    q.reset();
    expect(q.state, (total: 0, served: 0));
  });
}
