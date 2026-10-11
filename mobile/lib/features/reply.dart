import 'package:flutter/material.dart';

import '../data/platform_store.dart';
import '../ui/localized.dart';

class CaseReplyPage extends StatefulWidget {
  final PlatformStore store;
  final Record data;
  const CaseReplyPage({super.key, required this.store, required this.data});
  @override
  State<CaseReplyPage> createState() => _CaseReplyPageState();
}

class _CaseReplyPageState extends State<CaseReplyPage> {
  final message = TextEditingController();
  String? template, error;
  bool busy = false;
  @override
  void dispose() {
    message.dispose();
    super.dispose();
  }

  Future<void> send() async {
    if (message.text.trim().isEmpty) {
      setState(() => error = 'Complete this field');
      return;
    }
    final own =
        number(widget.data['user_id']) == number(widget.store.user['id']);
    final text = message.text.trim();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const UiText('Review reply'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              UiText(
                own
                    ? 'Recipient: assigned support team'
                    : 'Recipient: case customer',
              ),
              Text('Case ${widget.data['id']}'),
              const SizedBox(height: 12),
              Text(text),
              const SizedBox(height: 12),
              const UiText(
                'The recipient can read this reply in the app. Remove private information that is unnecessary for this case.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const UiText('Edit'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const UiText('Send reply'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final selected = records(widget.data['templates'])
          .where((r) => r['content_key'] == template)
          .firstOrNull;
      await widget.store.act('case-message', {
        'id': widget.data['id'],
        'version': widget.data['version'],
        'message': text,
        if (selected != null) 'template_key': template,
        if (selected != null) 'template_version': selected['version'],
      });
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const UiText('Reply')),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (records(widget.data['templates']).isNotEmpty)
            DropdownButtonFormField<String>(
              initialValue: template,
              decoration: InputDecoration(
                labelText: tr(context, 'Approved reply template'),
              ),
              items: [
                const DropdownMenuItem(
                  value: '',
                  child: UiText('Write your own reply'),
                ),
                for (final r in records(widget.data['templates']))
                  DropdownMenuItem(
                    value: '${r['content_key']}',
                    child: Text('${r['title']}'),
                  ),
              ],
              onChanged: busy
                  ? null
                  : (value) {
                      setState(() => template = value);
                      if (value != null && value.isNotEmpty) {
                        message.text =
                            '${records(widget.data['templates']).firstWhere((r) => r['content_key'] == value)['body']}';
                      }
                    },
            ),
          TextField(
            controller: message,
            maxLength: 4000,
            maxLines: 8,
            decoration: InputDecoration(labelText: tr(context, 'Your message')),
          ),
          if (error != null)
            Text(
              error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          FilledButton(
            onPressed: busy ? null : send,
            child: UiText(busy ? 'Saving reply…' : 'Review and send'),
          ),
        ],
      ),
    ),
  );
}
