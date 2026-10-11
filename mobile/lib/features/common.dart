import '../ui/localized.dart';

import 'package:flutter/material.dart';

import '../data/platform_store.dart';

Future<T?> openPage<T>(BuildContext context, Widget page) =>
    Navigator.of(context).push<T>(MaterialPageRoute(builder: (_) => page));
Future<void> perform(
  BuildContext context,
  Future<dynamic> Function() action,
) async {
  try {
    await action();
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: UiText('Saved')));
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'), duration: const Duration(seconds: 8)),
      );
    }
  }
}

Widget section(String title) => Padding(
  padding: const EdgeInsets.only(top: 24, bottom: 12),
  child: UiText(
    title,
    style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w700),
  ),
);
Widget empty(String text) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 32),
  child: Text(text),
);
Widget info(String title, dynamic value) =>
    ListTile(title: UiText(title), subtitle: UiText('$value'));

class FieldSpec {
  final String key, label;
  final String initial;
  final bool secret, multiline, optional;
  final List<String>? options;
  const FieldSpec(
    this.key,
    this.label, {
    this.initial = '',
    this.secret = false,
    this.multiline = false,
    this.optional = false,
    this.options,
  });
}

class ActionForm extends StatefulWidget {
  final String title, submit, description;
  final List<FieldSpec> fields;
  final Future<dynamic> Function(Record) action;
  const ActionForm({
    super.key,
    required this.title,
    required this.fields,
    required this.action,
    this.submit = 'Save',
    this.description = '',
  });
  @override
  State<ActionForm> createState() => _ActionFormState();
}

class _ActionFormState extends State<ActionForm> {
  final form = GlobalKey<FormState>();
  late final Map<String, TextEditingController> controllers;
  bool pending = false;
  String? error;
  @override
  void initState() {
    super.initState();
    controllers = {
      for (final f in widget.fields)
        f.key: TextEditingController(text: f.initial),
    };
  }

  @override
  void dispose() {
    for (final c in controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: UiText(widget.title)),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.description.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: UiText(widget.description),
                ),
              for (final f in widget.fields)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: f.options != null
                      ? DropdownButtonFormField<String>(
                          isExpanded: true,
                          initialValue: f.initial.isEmpty
                              ? f.options!.first
                              : f.initial,
                          decoration: InputDecoration(
                            labelText: tr(context, f.label),
                          ),
                          items: f.options!
                              .map(
                                (v) => DropdownMenuItem(
                                  value: v,
                                  child: Text(stage(v)),
                                ),
                              )
                              .toList(),
                          onChanged: (v) => controllers[f.key]!.text = v ?? '',
                          onSaved: (v) => controllers[f.key]!.text = v ?? '',
                        )
                      : TextFormField(
                          controller: controllers[f.key],
                          obscureText: f.secret,
                          maxLines: f.multiline ? 5 : 1,
                          decoration: InputDecoration(
                            labelText: tr(context, f.label),
                          ),
                          validator: (v) =>
                              !f.optional && (v ?? '').trim().isEmpty
                              ? tr(context, 'Complete this field')
                              : null,
                        ),
                ),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    error!,
                    semanticsLabel: 'Error: $error',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              FilledButton(
                onPressed: pending
                    ? null
                    : () async {
                        if (!form.currentState!.validate()) return;
                        form.currentState!.save();
                        setState(() {
                          pending = true;
                          error = null;
                        });
                        try {
                          await widget.action({
                            for (final e in controllers.entries)
                              e.key: e.value.text.trim(),
                          });
                          if (context.mounted) Navigator.pop(context, true);
                        } catch (e) {
                          if (mounted) {
                            setState(() {
                              error = '$e';
                            });
                          }
                        } finally {
                          if (mounted) setState(() => pending = false);
                        }
                      },
                child: pending
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(),
                      )
                    : UiText(widget.submit),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class DataPage extends StatefulWidget {
  final PlatformStore store;
  final String title, action, keyName;
  final Record query;
  final Widget Function(BuildContext, Record, VoidCallback) item;
  const DataPage({
    super.key,
    required this.store,
    required this.title,
    required this.action,
    required this.keyName,
    required this.item,
    this.query = const {},
  });
  @override
  State<DataPage> createState() => _DataPageState();
}

class _DataPageState extends State<DataPage> {
  Record? data;
  String? error;
  bool loading = false;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load({bool more = false}) async {
    if (loading) return;
    loading = true;
    try {
      final result = await widget.store.api(
        widget.action,
        query: {...widget.query, if (more) 'offset': data?['next_offset'] ?? 0},
      );
      if (more && data != null) {
        result[widget.keyName] = [
          ...records(data![widget.keyName]),
          ...records(result[widget.keyName]),
        ];
      }
      if (mounted) {
        setState(() {
          data = result;
          error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (e is ApiFailure && e.status == 403) data = null;
          error = '$e';
        });
      }
    } finally {
      loading = false;
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: UiText(widget.title),
      actions: [
        IconButton(
          onPressed: load,
          icon: const Icon(Icons.refresh),
          tooltip: 'Refresh',
        ),
      ],
    ),
    body: SafeArea(
      child: error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(error!),
                    TextButton(onPressed: load, child: const UiText('Retry')),
                  ],
                ),
              ),
            )
          : data == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => load(),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (records(data![widget.keyName]).isEmpty)
                    empty('Nothing here yet.'),
                  for (final item in records(data![widget.keyName]))
                    widget.item(context, item, () => load()),
                  if (data!['next_offset'] != null)
                    TextButton(
                      onPressed: () => load(more: true),
                      child: const UiText('Load more'),
                    ),
                ],
              ),
            ),
    ),
  );
}

int bdtMinor(String value) {
  final amount = double.tryParse(value.trim());
  if (amount == null || !amount.isFinite || amount < 0 || amount > 1000000) {
    throw ApiFailure('Enter a valid amount in BDT.', 422);
  }
  return (amount * 100).round();
}
