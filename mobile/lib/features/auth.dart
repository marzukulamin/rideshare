import '../ui/localized.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/platform_store.dart';
import 'common.dart';
import 'safety.dart';

class LoginPage extends StatefulWidget {
  final PlatformStore store;
  final VoidCallback? onTryDemo;
  const LoginPage({super.key, required this.store, this.onTryDemo});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final form = GlobalKey<FormState>(),
      phone = TextEditingController(),
      password = TextEditingController(),
      code = TextEditingController();
  bool pending = false, show = false;
  String? error;
  @override
  void dispose() {
    phone.dispose();
    password.dispose();
    code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.route, size: 48),
                  const SizedBox(height: 24),
                  const UiText(
                    'RideShare',
                    style: TextStyle(fontSize: 38, fontWeight: FontWeight.bold),
                  ),
                  const UiText('Your city. Your next ride.'),
                  if (widget.onTryDemo != null) ...[
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: widget.onTryDemo,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Try Demo'),
                    ),
                    const Text(
                      'Explore sample rides without an account or internet.',
                    ),
                  ],
                  if (widget.store.error != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      widget.store.error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: widget.store.loading
                          ? null
                          : widget.store.initialize,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry connection'),
                    ),
                  ],
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: phone,
                    keyboardType: TextInputType.phone,
                    autofillHints: const [AutofillHints.telephoneNumber],
                    decoration: InputDecoration(
                      labelText: tr(context, 'Phone number'),
                      hintText: tr(context, '+880…'),
                    ),
                    validator: (v) =>
                        (v ?? '').isEmpty ? 'Enter your phone number' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: password,
                    obscureText: !show,
                    autofillHints: const [AutofillHints.password],
                    decoration: InputDecoration(
                      labelText: tr(context, 'Password'),
                      suffixIcon: IconButton(
                        onPressed: () => setState(() => show = !show),
                        icon: Icon(
                          show ? Icons.visibility_off : Icons.visibility,
                        ),
                        tooltip: tr(context, 'Show or hide password'),
                      ),
                    ),
                    validator: (v) =>
                        (v ?? '').isEmpty ? 'Enter your password' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: code,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: InputDecoration(
                      labelText: tr(context, 'Staff authentication code'),
                      helperText: 'Required for staff accounts',
                    ),
                  ),
                  if (error != null)
                    Text(
                      error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: pending
                        ? null
                        : () async {
                            if (!form.currentState!.validate()) return;
                            setState(() {
                              pending = true;
                              error = null;
                            });
                            try {
                              await widget.store.login(
                                phone.text.trim(),
                                password.text,
                                code.text.trim(),
                              );
                            } catch (e) {
                              if (mounted) setState(() => error = '$e');
                            } finally {
                              if (mounted) setState(() => pending = false);
                            }
                          },
                    child: Text(pending ? 'Signing in…' : 'Sign in'),
                  ),
                  TextButton(
                    onPressed: () async {
                      try {
                        final result = await widget.store.api('public-terms');
                        final terms = records(result['terms']).firstOrNull;
                        if (terms == null) {
                          throw Exception(
                            'Service terms are unavailable. Try again later.',
                          );
                        }
                        if (!context.mounted) return;
                        final accepted = await showDialog<bool>(
                          context: context,
                          builder: (c) => AlertDialog(
                            title: Text(
                              '${terms['title']} · ${terms['version']}',
                            ),
                            content: SingleChildScrollView(
                              child: SelectableText('${terms['body']}'),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(c, false),
                                child: const UiText('Back'),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(c, true),
                                child: const UiText('Continue to account form'),
                              ),
                            ],
                          ),
                        );
                        if (accepted != true || !context.mounted) return;
                        await openPage(
                          context,
                          ActionForm(
                            title: 'Create customer account',
                            description:
                                'Accepting creates evidence for service terms ${terms['version']}. Contact verification is reviewed separately.',
                            fields: const [
                              FieldSpec('name', 'Full name'),
                              FieldSpec('phone', 'Phone number'),
                              FieldSpec(
                                'password',
                                'Password (12+ characters)',
                                secret: true,
                              ),
                            ],
                            submit: 'Accept terms and create account',
                            action: (b) => widget.store.api(
                              'signup',
                              body: {
                                ...b,
                                'accept_terms': true,
                                'terms_id': terms['id'],
                              },
                            ),
                          ),
                        );
                      } catch (e) {
                        if (mounted) setState(() => error = '$e');
                      }
                    },
                    child: const UiText('Create account'),
                  ),
                  TextButton(
                    onPressed: () => openPage(
                      context,
                      ActionForm(
                        title: 'Account recovery and urgent help',
                        description: 'Your request is recorded for review. This does not restore account access or dispatch emergency services.',
                        fields: const [
                          FieldSpec(
                            'kind',
                            'Request type',
                            options: ['recovery', 'appeal', 'urgent'],
                          ),
                          FieldSpec('contact', 'Contact details'),
                          FieldSpec(
                            'message',
                            'What happened?',
                            multiline: true,
                          ),
                        ],
                        action: (b) async {
                          final r = await widget.store.api(
                            'recovery-intake',
                            body: b,
                          );
                          if (!context.mounted) return;
                          await showDialog(
                            context: context,
                            builder: (c) => AlertDialog(
                              title: const UiText('Private case reference'),
                              content: SelectableText(
                                'Reference: ${r['reference']}\n\nPrivate access key: ${r['access_key']}\n\nKeep both to check status. Do not share this key publicly.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Clipboard.setData(
                                    ClipboardData(
                                      text:
                                          '${r['reference']}\n${r['access_key']}',
                                    ),
                                  ),
                                  child: const UiText('Copy reference and key'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(c),
                                  child: const UiText('Done'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    child: const UiText('Cannot sign in? Get help'),
                  ),
                  TextButton(
                    onPressed: () => openPage(
                      context,
                      ActionForm(
                        title: 'Check restricted case status',
                        fields: const [
                          FieldSpec('reference', 'Case reference'),
                          FieldSpec(
                            'access_key',
                            'Private access key',
                            secret: true,
                          ),
                        ],
                        action: (b) async {
                          final r = await widget.store.api(
                            'restricted-status',
                            body: b,
                          );
                          if (!context.mounted) return;
                          await showDialog(
                            context: context,
                            builder: (c) => AlertDialog(
                              title: Text(stage(r['status'])),
                              content: Text(
                                '${r['reply'] ?? 'Awaiting staff review'}\nUpdated ${r['updated_at']} UTC',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(c),
                                  child: const UiText('Close'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    child: const UiText('Check recovery or appeal status'),
                  ),
                  TextButton(
                    onPressed: () => openPage(
                      context,
                      ActionForm(
                        title: 'Complete approved account recovery',
                        description: 'Available after identity review and independent approval. All existing sessions are revoked. Driver identity recheck remains required.',
                        fields: const [
                          FieldSpec('reference', 'Case reference'),
                          FieldSpec(
                            'access_key',
                            'Private access key',
                            secret: true,
                          ),
                          FieldSpec(
                            'new_password',
                            'New password (12+ characters)',
                            secret: true,
                          ),
                        ],
                        action: (b) =>
                            widget.store.api('restricted-reset', body: b),
                      ),
                    ),
                    child: const UiText('Set password after approved recovery'),
                  ),
                  TextButton.icon(
                    onPressed: () =>
                        openPage(context, SafetyPage(store: widget.store)),
                    icon: const Icon(Icons.shield_outlined),
                    label: const UiText('Emergency dialer'),
                  ),
                  TextButton(
                    onPressed: () async {
                      await perform(context, () async {
                        final r = await widget.store.api('public-terms');
                        if (!context.mounted) return;
                        await showDialog(
                          context: context,
                          builder: (c) => AlertDialog(
                            title: const UiText('Service terms'),
                            content: SingleChildScrollView(
                              child: Text(
                                records(r['terms'])
                                    .map((t) => '${t['title']}\n${t['body']}')
                                    .join('\n'),
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(c),
                                child: const UiText('Close'),
                              ),
                            ],
                          ),
                        );
                      });
                    },
                    child: const UiText('Service terms'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
