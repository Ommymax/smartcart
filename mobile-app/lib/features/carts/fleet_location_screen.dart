import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'cart_detail_screen.dart';
import 'cart_provider.dart';

class FleetLocationScreen extends StatelessWidget {
  const FleetLocationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CartProvider>();
    final located = provider.carts.where((cart) {
      final t = provider.latestTelemetry[cart.cartId] ?? cart.latestTelemetry;
      return t?.locationAvailable == true && t?.latitude != null && t?.longitude != null;
    }).toList();

    final firstTelemetry = located.isEmpty ? null : provider.latestTelemetry[located.first.cartId] ?? located.first.latestTelemetry;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Cart location', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 6),
        const Text('Shows current smart cart position when GPS or mobile location data is available.'),
        const SizedBox(height: 16),
        SizedBox(
          height: 320,
          child: Card(
            clipBehavior: Clip.antiAlias,
            child: firstTelemetry == null
                ? const _MapPlaceholder()
                : GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(firstTelemetry.latitude!.toDouble(), firstTelemetry.longitude!.toDouble()),
                      zoom: 18,
                    ),
                    markers: {
                      for (final cart in located)
                        Marker(
                          markerId: MarkerId(cart.cartId),
                          position: LatLng(
                            (provider.latestTelemetry[cart.cartId] ?? cart.latestTelemetry)!.latitude!.toDouble(),
                            (provider.latestTelemetry[cart.cartId] ?? cart.latestTelemetry)!.longitude!.toDouble(),
                          ),
                          infoWindow: InfoWindow(title: cart.cartName, snippet: cart.cartId),
                        ),
                    },
                  ),
          ),
        ),
        const SizedBox(height: 16),
        if (provider.carts.isEmpty)
          const _InfoCard(
            icon: Icons.add_shopping_cart,
            title: 'No smart cart added',
            message: 'Open Carts and add the ESP32 cart ID first.',
          )
        else
          ...provider.carts.map((cart) {
            final t = provider.latestTelemetry[cart.cartId] ?? cart.latestTelemetry;
            final online = cart.isOnline;
            final hasLocation = t?.locationAvailable == true && t?.latitude != null && t?.longitude != null;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: online ? Colors.green.shade100 : Colors.red.shade100,
                    child: Icon(online ? Icons.wifi : Icons.wifi_off, color: online ? Colors.green : Colors.red),
                  ),
                  title: Text(cart.cartName),
                  subtitle: Text(
                    hasLocation
                        ? '${t!.latitude}, ${t.longitude} - ${online ? 'online' : 'offline'}'
                        : 'Location unavailable. GPS module or mobile location integration is required.',
                  ),
                  trailing: Icon(hasLocation ? Icons.place : Icons.location_off),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => CartDetailScreen(cart: cart))),
                ),
              ),
            );
          }),
      ],
    );
  }
}

class _MapPlaceholder extends StatelessWidget {
  const _MapPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.map_outlined, size: 64, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 12),
              Text('Map waiting for GPS data', style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              const Text(
                'When ESP32 telemetry includes latitude and longitude, the cart marker will appear here.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.icon, required this.title, required this.message});
  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  Text(message),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
