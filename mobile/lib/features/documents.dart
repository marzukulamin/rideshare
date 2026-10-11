import '../ui/localized.dart';

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../data/platform_store.dart';
import 'common.dart';

class DocumentPage extends StatefulWidget {
  final PlatformStore store;
  final dynamic id;
  final bool attachment;
  const DocumentPage({
    super.key,
    required this.store,
    required this.id,
    this.attachment = false,
  });
  @override
  State<DocumentPage> createState() => _DocumentPageState();
}

class _DocumentPageState extends State<DocumentPage> {
  Record? data;
  String? error;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final r = await widget.store.api(
        widget.attachment ? 'attachment-data' : 'document-data',
        query: {'id': widget.id},
      );
      if (mounted) setState(() => data = r);
    } catch (e) {
      if (mounted) {
        setState(() {
          if (e is ApiFailure && e.status == 403) data = null;
          error = '$e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const UiText('Private document')),
    body: SafeArea(
      child: data == null
          ? Center(
              child: error == null
                  ? const CircularProgressIndicator()
                  : Text(error!),
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const UiText(
                  'Private evidence. Review only for the assigned purpose. A downloaded copy leaves the app’s protected storage.',
                ),
                info('Document', stage(data!['kind'])),
                info('Review status', stage(data!['status'])),
                if (data!['mime'] != 'application/pdf')
                  InteractiveViewer(
                    child: Image.memory(base64Decode(data!['data'])),
                  )
                else
                  FilledButton.icon(
                    onPressed: () => perform(context, () async {
                      await Printing.sharePdf(
                        bytes: base64Decode(data!['data']),
                        filename: 'private-document-${widget.id}.pdf',
                      );
                    }),
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const UiText('Open or save PDF for review'),
                  ),
              ],
            ),
    ),
  );
}
