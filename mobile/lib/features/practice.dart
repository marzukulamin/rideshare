import '../ui/localized.dart';

import 'package:flutter/material.dart';

class DriverPracticePage extends StatefulWidget {
  const DriverPracticePage({super.key});
  @override
  State<DriverPracticePage> createState() => _DriverPracticePageState();
}

class _DriverPracticePageState extends State<DriverPracticePage> {
  int step = 0;
  static const instructions = [
    'Check readiness, your approved vehicle, documents and location permission before going online.',
    'Read the pickup, destination, earning basis and expiry. Accept only when you can safely serve the request.',
    'Head to the confirmed pickup. Mark arrival only when you reach the meeting point; the server records the wait start.',
    'Ask the customer for their pickup PIN. Only the assigned driver starts the trip after successful verification.',
    'Follow the accepted route. Review a customer’s requested change and its price before accepting it.',
    'End the trip at the agreed destination. Record cash after receipt; the customer confirms collection. Report a disagreement through Help.',
  ];
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const UiText('Driver practice')),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Icon(Icons.school_outlined, size: 60),
          const UiText(
            'Practice only · no trip, fare, cash collection or earnings are created.',
          ),
          const SizedBox(height: 24),
          Text(
            'Step ${step + 1} of ${instructions.length}',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          Text(instructions[step]),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () =>
                setState(() => step = (step + 1) % instructions.length),
            child: Text(
              step == instructions.length - 1 ? 'Practice again' : 'Next step',
            ),
          ),
        ],
      ),
    ),
  );
}
