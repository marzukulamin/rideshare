import 'package:flutter/material.dart';

import '../data/offline_demo.dart';
import '../ui/road_map.dart';

class DemoWelcomePage extends StatelessWidget {
  final VoidCallback onDemo, onSignIn;
  const DemoWelcomePage({
    super.key,
    required this.onDemo,
    required this.onSignIn,
  });
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(28),
            children: [
              const Icon(Icons.route, size: 64),
              const SizedBox(height: 24),
              Text(
                'RideShare',
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const SizedBox(height: 12),
              Text(
                'Your next ride. Take a look around.',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 20),
              const Text(
                'Explore a sample booking, meet your demo driver and follow a simulated trip. No account or internet needed.',
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onDemo,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Try Demo'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: onSignIn,
                child: const Text('Sign in with an account'),
              ),
              const SizedBox(height: 16),
              const Text(
                'Demo rides use sample data. Real account sign-in requires a connected server.',
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class OfflineDemoPage extends StatefulWidget {
  final VoidCallback onExit;
  const OfflineDemoPage({super.key, required this.onExit});
  @override
  State<OfflineDemoPage> createState() => _OfflineDemoPageState();
}

class _OfflineDemoPageState extends State<OfflineDemoPage> {
  final demo = OfflineDemoSession();
  @override
  void dispose() {
    demo.dispose();
    super.dispose();
  }

  Widget heading(String text) => Padding(
    padding: const EdgeInsets.only(top: 20, bottom: 12),
    child: Text(text, style: Theme.of(context).textTheme.titleLarge),
  );
  Widget itinerary(DemoRide ride) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.my_location),
        title: Text(ride.pickup.name),
        subtitle: const Text('Pickup'),
      ),
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.location_on_outlined),
        title: Text(ride.destination.name),
        subtitle: const Text('Destination'),
      ),
      Text(
        '${ride.vehicle} · ${ride.distanceKm.toStringAsFixed(1)} km illustrative distance',
      ),
    ],
  );
  void review() {
    if (!demo.reviewFare()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Choose different pickup and destination places.'),
        ),
      );
    }
  }

  Widget home() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        'Let’s get you there',
        style: Theme.of(context).textTheme.headlineLarge,
      ),
      const SizedBox(height: 8),
      const Text('Choose a route and explore a ride at your own pace.'),
      const SizedBox(height: 20),
      RoadMap(pins: [demo.pickup.pin, demo.destination.pin]),
      heading('Plan a demo ride'),
      DropdownButtonFormField<DemoPlace>(
        initialValue: demo.pickup,
        isExpanded: true,
        decoration: const InputDecoration(labelText: 'Pickup'),
        items: OfflineDemoSession.places
            .map((p) => DropdownMenuItem(value: p, child: Text(p.name)))
            .toList(),
        onChanged: (p) => demo.select(from: p),
      ),
      const SizedBox(height: 16),
      DropdownButtonFormField<DemoPlace>(
        initialValue: demo.destination,
        isExpanded: true,
        decoration: const InputDecoration(labelText: 'Destination'),
        items: OfflineDemoSession.places
            .map((p) => DropdownMenuItem(value: p, child: Text(p.name)))
            .toList(),
        onChanged: (p) => demo.select(to: p),
      ),
      const SizedBox(height: 16),
      DropdownButtonFormField<String>(
        initialValue: demo.vehicle,
        decoration: const InputDecoration(labelText: 'Vehicle'),
        items: OfflineDemoSession.vehicles
            .map((p) => DropdownMenuItem(value: p, child: Text(p)))
            .toList(),
        onChanged: (p) => demo.select(product: p),
      ),
      const SizedBox(height: 20),
      FilledButton.icon(
        onPressed: review,
        icon: const Icon(Icons.receipt_long),
        label: Text(
          demo.current != null && !demo.current!.ended
              ? 'Continue demo ride'
              : 'Review demo fare',
        ),
      ),
      const SizedBox(height: 12),
      const Text('Illustrative fares and routes. No real booking or payment.'),
    ],
  );

  Widget ride() {
    final trip = demo.current ?? demo.preview;
    if (trip == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          heading('Your demo ride'),
          const Text('Choose your route to begin a simulated ride.'),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () => demo.navigate(0),
            child: const Text('Choose a route'),
          ),
        ],
      );
    }
    final booked = demo.current != null;
    final driverVisible = booked && trip.step >= 1 && trip.step < 5;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          booked ? trip.status : 'Review your demo fare',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 16),
        RoadMap(
          pins: [trip.pickup.pin, trip.destination.pin],
          route: [trip.pickup.pin, trip.destination.pin],
          driver: driverVisible && !trip.ended
              ? (trip.step >= 3 ? trip.destination.pin : trip.pickup.pin)
              : null,
        ),
        const SizedBox(height: 12),
        itinerary(trip),
        heading('৳${trip.fare} · sample fare'),
        const Text('Cash payment is simulated. No money changes hands.'),
        if (driverVisible)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(child: Icon(Icons.person_outline)),
                    title: Text('Mina · demo driver'),
                    subtitle: Text('Sample vehicle · DEMO 1234'),
                  ),
                  if (trip.step == 2)
                    const Text(
                      'Sample pickup PIN: 2468',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  Text(
                    trip.step == 4 ? 'Thanks for exploring RideShare.' : 'Use the next button to simulate the driver’s next action.',
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 20),
        if (!booked)
          FilledButton(
            onPressed: demo.book,
            child: const Text('Simulate booking'),
          ),
        if (booked && !trip.ended) ...[
          Text('Demo step ${trip.step + 1} of 5'),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: (trip.step + 1) / 5),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: demo.advance,
            child: Text(
              const [
                'Simulate driver match',
                'Simulate arrival',
                'Simulate pickup',
                'Complete demo ride',
              ][trip.step],
            ),
          ),
          TextButton(
            onPressed: demo.cancel,
            child: const Text('Cancel demo ride'),
          ),
        ],
        if (booked && trip.ended) ...[
          Text(
            trip.step == 4
                ? 'Sample receipt saved in Activity.'
                : 'Cancelled. No driver was contacted.',
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => demo.navigate(2),
            child: const Text('View demo activity'),
          ),
          TextButton(
            onPressed: () => demo.navigate(0),
            child: const Text('Plan another demo ride'),
          ),
        ],
      ],
    );
  }

  Widget activity() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text('Demo activity', style: Theme.of(context).textTheme.headlineLarge),
      const SizedBox(height: 8),
      const Text('Sample trips and the rides you simulate in this session.'),
      for (final trip in demo.history)
        Card(
          child: ListTile(
            leading: const Icon(Icons.receipt_long_outlined),
            title: Text('${trip.destination.name} · ৳${trip.fare}'),
            subtitle: Text(
              '${trip.vehicle} · ${trip.status}\n${trip.example ? 'Sample trip' : 'This demo session'}',
            ),
            isThreeLine: true,
            onTap: () => showDialog<void>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Demo trip details'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      itinerary(trip),
                      const SizedBox(height: 16),
                      Text(
                        '${trip.status}\nSample total: ৳${trip.fare}\nNo payment was collected.',
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
          ),
        ),
    ],
  );

  Widget account() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text('Demo guest', style: Theme.of(context).textTheme.headlineLarge),
      const SizedBox(height: 12),
      const Text(
        'You are exploring a local sample experience. No account, location access or internet connection is needed.',
      ),
      heading('About this demo'),
      const Text(
        'All drivers, rides, prices and payments here are simulated. Demo changes stay in memory and reset when you leave or restart the app.',
      ),
      const SizedBox(height: 20),
      OutlinedButton.icon(
        onPressed: demo.reset,
        icon: const Icon(Icons.restart_alt),
        label: const Text('Reset demo'),
      ),
      const SizedBox(height: 12),
      TextButton(onPressed: widget.onExit, child: const Text('Exit demo')),
    ],
  );

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: demo,
    builder: (context, _) => Scaffold(
      appBar: AppBar(
        title: const Text('RideShare · Demo'),
        actions: [
          TextButton(onPressed: widget.onExit, child: const Text('Exit demo')),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  child: Text(
                    'Offline demo · Sample data · No real rides',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView(
                    key: ValueKey('${demo.tab}:${demo.current?.step}'),
                    padding: const EdgeInsets.all(20),
                    children: [
                      switch (demo.tab) {
                        0 => home(),
                        1 => ride(),
                        2 => activity(),
                        _ => account(),
                      },
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: demo.tab,
        onDestinationSelected: demo.navigate,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.route), label: 'Ride'),
          NavigationDestination(icon: Icon(Icons.history), label: 'Activity'),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Account',
          ),
        ],
      ),
    ),
  );
}
