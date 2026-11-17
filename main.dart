import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ai_service.dart';
import 'models.dart';
import 'storage_factory.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PulseApp());
}

class PulseApp extends StatelessWidget {
  const PulseApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'PULSE AI', debugShowCheckedModeBanner: false,
    theme: ThemeData(useMaterial3: true, scaffoldBackgroundColor: const Color(0xFFF5F5F0),
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF5755D9)),
      textTheme: Theme.of(context).textTheme.apply(fontFamily: 'Roboto')),
    home: const PulseHome());
}

class PulseHome extends StatefulWidget {
  const PulseHome({super.key});
  @override State<PulseHome> createState() => _PulseHomeState();
}

class _PulseHomeState extends State<PulseHome> {
  final input = TextEditingController();
  final scroll = ScrollController();
  final ai = PulseAiService();
  final secrets = const FlutterSecureStorage();
  PulseStorage? storage;
  List<ChatMessage> messages = [];
  List<MemoryItem> memories = [];
  bool busy = false;
  String? error;
  String model = 'gpt-4o-mini';
  int tab = 0;

  @override void initState() { super.initState(); _initialize(); }
  Future<void> _initialize() async {
    try {
      final s = await PulseStorage.open();
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) { await s.close(); return; }
      storage = s;
      model = prefs.getString('model') ?? 'gpt-4o-mini';
      await _refresh();
    } catch (e) { if (mounted) setState(() => error = 'Storage initialization failed: $e'); }
  }
  Future<void> _refresh() async {
    final s = storage;
    if (s == null) return;
    final nextMessages = await s.messages();
    final nextMemories = await s.memories();
    if (mounted) setState(() { messages = nextMessages; memories = nextMemories; });
  }
  Future<void> _send() async {
    final value = input.text.trim();
    final s = storage;
    if (value.isEmpty || s == null || busy) return;
    input.clear();
    setState(() { busy = true; error = null; });
    try {
      await s.addMessage('user', value);
      await _refresh();
      if (kIsWeb) throw StateError('Cloud chat is disabled on the public web preview until a secure server proxy is configured. Local memory works.');
      final key = await secrets.read(key: 'openai_api_key') ?? '';
      final result = await ai.reply(apiKey: key, model: model, messages: messages, memories: memories);
      await s.addMessage('assistant', result);
      await _refresh();
    } catch (e) { if (mounted) setState(() => error = e.toString().replaceFirst('Bad state: ', '')); }
    finally { if (mounted) setState(() => busy = false); }
    if (scroll.hasClients) scroll.animateTo(scroll.position.maxScrollExtent,
      duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic);
  }
  @override void dispose() { input.dispose(); scroll.dispose(); ai.dispose(); storage?.close(); super.dispose(); }
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(backgroundColor: Colors.transparent,
      title: const Text('PULSE', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 3)),
      actions: [IconButton(tooltip: 'Settings', icon: const Icon(Icons.tune_rounded), onPressed: () => setState(() => tab = 2))]),
    body: SafeArea(child: Column(children: [
      Expanded(child: IndexedStack(index: tab, children: [_chat(), _memory(), _settings()])),
      NavigationBar(selectedIndex: tab, onDestinationSelected: (i) => setState(() => tab = i),
        destinations: const [NavigationDestination(icon: Icon(Icons.auto_awesome_outlined), label: 'Assistant'),
          NavigationDestination(icon: Icon(Icons.psychology_outlined), label: 'Memory'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'Settings')]),
    ])));

  Widget _chat() => Column(children: [
    Expanded(child: messages.isEmpty ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      const PulseOrb(), const SizedBox(height: 28),
      const Text('What can I help you explore?', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8), Text('Your ideas, one conversation away.', style: TextStyle(color: Colors.grey.shade600)),
    ])) : ListView.builder(controller: scroll, padding: const EdgeInsets.all(18), itemCount: messages.length,
      itemBuilder: (context, i) { final m = messages[i]; final mine = m.role == 'user';
        return Align(alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
          child: AnimatedContainer(duration: const Duration(milliseconds: 320), curve: Curves.easeOutCubic,
            constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * .84),
            margin: const EdgeInsets.symmetric(vertical: 7), padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: mine ? const Color(0xFF202024) : Colors.white,
              borderRadius: BorderRadius.circular(22), boxShadow: const [BoxShadow(color: Color(0x10000000), blurRadius: 18, offset: Offset(0, 6))]),
            child: SelectableText(m.content, style: TextStyle(color: mine ? Colors.white : const Color(0xFF202024), height: 1.45))));
      })),
    if (busy) const Padding(padding: EdgeInsets.all(8), child: LinearProgressIndicator(minHeight: 2)),
    if (error != null) Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Text(error!, style: const TextStyle(color: Colors.redAccent))),
    Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 16), child: Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(26),
        boxShadow: const [BoxShadow(color: Color(0x13000000), blurRadius: 24, offset: Offset(0, 8))]),
      child: Row(children: [Expanded(child: TextField(controller: input, enabled: storage != null && !busy,
        textInputAction: TextInputAction.send, onSubmitted: (_) => _send(), maxLines: 4, minLines: 1,
        decoration: const InputDecoration(hintText: 'Ask PULSE anything', border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 16)))),
        IconButton(tooltip: 'Send message', onPressed: busy ? null : _send,
          icon: const Icon(Icons.arrow_upward_rounded))]))),
  ]);

  Widget _memory() => ListView(padding: const EdgeInsets.all(20), children: [
    const Text('Your memory, your control', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
    const SizedBox(height: 8), const Text('Only facts you explicitly save appear here. Delete any at any time.'),
    const SizedBox(height: 18), FilledButton.icon(onPressed: storage == null ? null : _addMemoryDialog,
      icon: const Icon(Icons.add), label: const Text('Save a memory')),
    const SizedBox(height: 16),
    for (final m in memories) Card(color: Colors.white, child: ListTile(
      title: Text(m.content), trailing: IconButton(tooltip: 'Delete memory', icon: const Icon(Icons.delete_outline),
        onPressed: () async { await storage?.removeMemory(m.id); await _refresh(); }))),
    if (memories.isEmpty) const Padding(padding: EdgeInsets.all(24), child: Center(child: Text('No memories saved yet.'))),
  ]);

  Future<void> _addMemoryDialog() async {
    final field = TextEditingController();
    final result = await showDialog<String>(context: context, builder: (context) => AlertDialog(
      title: const Text('Remember something'), content: TextField(controller: field, autofocus: true,
        maxLines: 3, decoration: const InputDecoration(hintText: 'For example: I prefer concise answers')),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(context, field.text), child: const Text('Save'))]));
    field.dispose();
    if (result == null || result.trim().isEmpty) return;
    await storage?.addMemory(result);
    await _refresh();
  }

  Widget _settings() => ListView(padding: const EdgeInsets.all(20), children: [
    const Text('Connection & privacy', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
    const SizedBox(height: 12), const Text('Chat and approved memories stay in local device storage (SQLite on Android, browser storage on web). '
      'When you send a message, recent chat and saved memories are sent to your configured AI provider.'),
    if (kIsWeb) const Padding(padding: EdgeInsets.only(top: 12), child: Text('Web preview: local memory and chat history work. AI replies require a secure backend; API keys must never be embedded in a public website.')),
    const SizedBox(height: 18), Card(color: Colors.white, child: ListTile(
      leading: const Icon(Icons.key), title: const Text('OpenAI API key'),
      subtitle: Text(kIsWeb ? 'Unavailable on public web preview' : 'Stored in Android secure storage'),
      trailing: const Icon(Icons.chevron_right), onTap: kIsWeb ? null : _keyDialog)),
    Card(color: Colors.white, child: ListTile(leading: const Icon(Icons.smart_toy_outlined),
      title: const Text('Model'), subtitle: Text(model), onTap: _modelDialog)),
    const SizedBox(height: 20), OutlinedButton.icon(onPressed: storage == null ? null : () async {
      final confirmed = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
        title: const Text('Delete conversation history?'),
        content: const Text('This permanently removes local messages, but not saved memories.'),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete'))]));
      if (confirmed == true) { await storage?.clearMessages(); await _refresh(); }
    }, icon: const Icon(Icons.delete_outline), label: const Text('Delete conversation history')),
  ]);
  Future<void> _keyDialog() async {
    final field = TextEditingController();
    final value = await showDialog<String>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Set API key'), content: TextField(controller: field, obscureText: true,
        autocorrect: false, enableSuggestions: false, decoration: const InputDecoration(hintText: 'sk-...')),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(ctx, field.text.trim()), child: const Text('Save'))]));
    field.dispose();
    if (value != null && value.isNotEmpty) await secrets.write(key: 'openai_api_key', value: value);
  }
  Future<void> _modelDialog() async {
    final field = TextEditingController(text: model);
    final value = await showDialog<String>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Model identifier'), content: TextField(controller: field,
        decoration: const InputDecoration(hintText: 'gpt-4o-mini')),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(ctx, field.text.trim()), child: const Text('Save'))]));
    field.dispose();
    if (value != null && value.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('model', value);
      if (mounted) setState(() => model = value);
    }
  }
}

class PulseOrb extends StatefulWidget {
  const PulseOrb({super.key});
  @override State<PulseOrb> createState() => _PulseOrbState();
}
class _PulseOrbState extends State<PulseOrb> with SingleTickerProviderStateMixin {
  late final AnimationController controller = AnimationController(vsync: this,
    duration: const Duration(milliseconds: 2400))..repeat(reverse: true);
  @override void dispose() { controller.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => AnimatedBuilder(animation: controller,
    builder: (context, child) => Transform.scale(scale: 0.94 + controller.value * .1,
      child: Container(width: 110, height: 110,
        decoration: BoxDecoration(shape: BoxShape.circle,
          gradient: const RadialGradient(center: Alignment(-.3, -.4), colors: [Color(0xFFB9AFFF), Color(0xFF6258D6), Color(0xFF272B85)]),
          boxShadow: [BoxShadow(color: const Color(0xFF6E62E6).withValues(alpha: .18 + controller.value * .23),
            blurRadius: 22 + controller.value * 26, spreadRadius: 3 + controller.value * 4)]),
        child: const Icon(Icons.auto_awesome, color: Colors.white, size: 34))));
}
