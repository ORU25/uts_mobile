import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

const appName = 'MBG Makan Bebek Goreng';

// ===== STATE MANAGEMENT (Cubit) =====

typedef ThemeState = ({Color seed, bool dark});

class ThemeCubit extends Cubit<ThemeState> {
  ThemeCubit() : super((seed: themeColors.values.first, dark: false));

  void setSeed(Color c) => emit((seed: c, dark: state.dark));
  void toggleDark() => emit((seed: state.seed, dark: !state.dark));
}

/// total = nomor terakhir yang diambil, served = nomor yang sedang dilayani.
typedef QueueState = ({int total, int served});

class QueueCubit extends Cubit<QueueState> {
  QueueCubit() : super((total: 0, served: 0));

  void takeNumber() => emit((total: state.total + 1, served: state.served));
  void callNext() {
    if (state.served < state.total) {
      emit((total: state.total, served: state.served + 1));
    }
  }

  /// Batalkan nomor terakhir yang belum dilayani.
  void cancel() {
    if (state.total > state.served) {
      emit((total: state.total - 1, served: state.served));
    }
  }

  void reset() => emit((total: 0, served: 0));
}

String fmt(int n) => 'A-${n.toString().padLeft(3, '0')}';

// Warna diambil dari logo MBG.
const themeColors = <String, Color>{
  'Biru Navy': Color(0xFF3D6FD6),
  'Emas': Color(0xFFF2B630),
  'Oranye Paruh': Color(0xFFFF9F1C),
  'Coklat Goreng': Color(0xFFD9822B),
  'Hijau Daun': Color(0xFF7CC243),
  'Krem Bebek': Color(0xFFF5D98B),
};

// ===== APP =====

void main() => runApp(const App());

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ThemeCubit()),
        BlocProvider(create: (_) => QueueCubit()),
      ],
      child: BlocBuilder<ThemeCubit, ThemeState>(
        builder: (context, t) => MaterialApp(
          title: appName,
          debugShowCheckedModeBanner: false,
          themeMode: t.dark ? ThemeMode.dark : ThemeMode.light,
          theme: _theme(t.seed, Brightness.light),
          darkTheme: _theme(t.seed, Brightness.dark),
          home: const HomePage(),
        ),
      ),
    );
  }
}

// vibrant: warna cerah, tapi Material 3 tetap menjaga kontras teks
// (gelap di mode terang, terang di mode gelap).
ThemeData _theme(Color seed, Brightness b) => ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: seed,
        brightness: b,
        dynamicSchemeVariant: DynamicSchemeVariant.vibrant,
      ),
    );

// ===== WIDGET BERSAMA =====

class Logo extends StatelessWidget {
  const Logo({super.key, this.size = 80});
  final double size;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: cs.primary.withValues(alpha: .4), blurRadius: 16)],
      ),
      child: Image.asset('assets/logo.png'),
    );
  }
}

/// Background gradasi, ikut warna tema.
class Background extends StatelessWidget {
  const Background({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [cs.primaryContainer, cs.surface, cs.tertiaryContainer],
        ),
      ),
      child: SafeArea(child: child),
    );
  }
}

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  void _go(BuildContext context, Widget page) {
    Navigator.pop(context);
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = context.watch<ThemeCubit>().state;
    return Drawer(
      child: ListView(padding: EdgeInsets.zero, children: [
        DrawerHeader(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [cs.primary, cs.tertiary]),
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Logo(size: 64),
            const SizedBox(height: 8),
            Text(appName,
                style: TextStyle(color: cs.onPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
          ]),
        ),
        ListTile(
          leading: const Icon(Icons.home),
          title: const Text('Beranda'),
          onTap: () => _go(context, const HomePage()),
        ),
        ListTile(
          leading: const Icon(Icons.confirmation_number),
          title: const Text('Hitung Antrian'),
          onTap: () => _go(context, const QueuePage()),
        ),
        const Divider(),
        SwitchListTile(
          secondary: Icon(t.dark ? Icons.dark_mode : Icons.light_mode),
          title: const Text('Mode Gelap'),
          value: t.dark,
          onChanged: (_) => context.read<ThemeCubit>().toggleDark(),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Text('Warna Tema'),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(spacing: 10, runSpacing: 10, children: [
            for (final e in themeColors.entries)
              Tooltip(
                message: e.key,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => context.read<ThemeCubit>().setSeed(e.value),
                  child: CircleAvatar(
                    backgroundColor: e.value,
                    child: t.seed == e.value ? const Icon(Icons.check, color: Colors.white) : null,
                  ),
                ),
              ),
          ]),
        ),
      ]),
    );
  }
}

// ===== HALAMAN =====

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final q = context.watch<QueueCubit>().state;
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Beranda'), backgroundColor: Colors.transparent),
      extendBodyBehindAppBar: true,
      drawer: const AppDrawer(),
      body: Background(
        child: ListView(padding: const EdgeInsets.fromLTRB(20, 72, 20, 20), children: [
          const SizedBox(height: 8),
          const Center(child: Logo(size: 160)),
          const SizedBox(height: 20),
          Text('Selamat Datang di',
              textAlign: TextAlign.center,
              style: tt.titleMedium?.copyWith(color: cs.onSurfaceVariant, letterSpacing: 1)),
          Text(appName,
              textAlign: TextAlign.center,
              style: tt.headlineMedium?.copyWith(color: cs.primary, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 60,
              height: 4,
              decoration: BoxDecoration(color: cs.tertiary, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 12),
          Text('Kelola antrian pembeli dengan mudah, cepat, dan tertib.',
              textAlign: TextAlign.center, style: tt.bodyLarge),
          const SizedBox(height: 32),
          Text('Ringkasan Hari Ini', style: tt.titleMedium),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: _StatCard(Icons.confirmation_number, '${q.total}', 'Nomor Diambil')),
            const SizedBox(width: 16),
            Expanded(
              child: _StatCard(Icons.record_voice_over, q.served == 0 ? '-' : fmt(q.served), 'Sedang Dilayani'),
            ),
          ]),
          const SizedBox(height: 16),
          _StatCard(Icons.hourglass_bottom, '${q.total - q.served} orang', 'Menunggu'),
          const SizedBox(height: 24),
          FilledButton.icon(
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            icon: const Icon(Icons.people),
            label: const Text('Buka Hitung Antrian'),
            onPressed: () => Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (_) => const QueuePage())),
          ),
        ]),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard(this.icon, this.value, this.label);
  final IconData icon;
  final String value, label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      color: cs.surfaceContainerHighest.withValues(alpha: .8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
        child: Column(children: [
          Icon(icon, color: cs.primary, size: 32),
          const SizedBox(height: 8),
          Text(value, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
          Text(label),
        ]),
      ),
    );
  }
}

class QueuePage extends StatelessWidget {
  const QueuePage({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<QueueCubit>();
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hitung Antrian'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(tooltip: 'Reset', icon: const Icon(Icons.restart_alt), onPressed: cubit.reset),
        ],
      ),
      extendBodyBehindAppBar: true,
      drawer: const AppDrawer(),
      body: Background(
        child: BlocBuilder<QueueCubit, QueueState>(
          builder: (context, q) => ListView(padding: const EdgeInsets.fromLTRB(20, 72, 20, 20), children: [
            Card(
              color: cs.primary,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Column(children: [
                  Text('SEDANG DILAYANI',
                      style: tt.titleMedium?.copyWith(color: cs.onPrimary, letterSpacing: 2)),
                  const SizedBox(height: 12),
                  Text(q.served == 0 ? '—' : fmt(q.served),
                      key: const Key('served'),
                      style: tt.displayMedium?.copyWith(color: cs.onPrimary, fontWeight: FontWeight.bold)),
                ]),
              ),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _InfoCard(Icons.hourglass_bottom, 'Menunggu', '${q.total - q.served} orang')),
              const SizedBox(width: 16),
              Expanded(
                child: _InfoCard(Icons.confirmation_number, 'Nomor Terakhir', q.total == 0 ? '-' : fmt(q.total)),
              ),
            ]),
            const SizedBox(height: 16),
            FilledButton.icon(
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              icon: const Icon(Icons.campaign),
              label: const Text('Panggil Berikutnya'),
              onPressed: q.served < q.total ? cubit.callNext : null,
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(44)),
                  icon: const Icon(Icons.remove),
                  label: const Text('Batal'),
                  onPressed: q.total > q.served ? cubit.cancel : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(44)),
                  icon: const Icon(Icons.add),
                  label: const Text('Ambil Nomor'),
                  onPressed: cubit.takeNumber,
                ),
              ),
            ]),
            const SizedBox(height: 24),
            Text('Daftar Menunggu', style: tt.titleMedium),
            const SizedBox(height: 8),
            _Chips([for (var i = q.served + 1; i <= q.total; i++) i], Icons.person),
            const SizedBox(height: 24),
            Text('Sudah Dilayani (${q.served})', style: tt.titleMedium),
            const SizedBox(height: 8),
            _Chips([for (var i = q.served; i >= 1; i--) i], Icons.check_circle),
          ]),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard(this.icon, this.label, this.value);
  final IconData icon;
  final String label, value;

  @override
  Widget build(BuildContext context) => Card(
        color: Theme.of(context).colorScheme.primaryContainer,
        child: ListTile(
          leading: Icon(icon),
          title: Text(label),
          subtitle: Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      );
}

class _Chips extends StatelessWidget {
  const _Chips(this.numbers, this.icon);
  final List<int> numbers;
  final IconData icon;

  @override
  Widget build(BuildContext context) => numbers.isEmpty
      ? const Text('Belum ada.')
      : Wrap(spacing: 8, runSpacing: 8, children: [
          for (final n in numbers) Chip(avatar: Icon(icon, size: 18), label: Text(fmt(n))),
        ]);
}
