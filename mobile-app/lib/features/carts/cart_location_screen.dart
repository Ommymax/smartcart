import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../shared/models/cart.dart';
import 'cart_provider.dart';

class CartLocationScreen extends StatelessWidget {
  const CartLocationScreen({super.key, required this.cart});
  final CartItem cart;

  @override
  Widget build(BuildContext context) {
    final telemetry = context.watch<CartProvider>().latestTelemetry[cart.cartId] ?? cart.latestTelemetry;
    final hasLocation = telemetry?.locationAvailable == true && telemetry?.latitude != null && telemetry?.longitude != null;
    return Scaffold(
      appBar: AppBar(title: Text('Location ${cart.cartId}')),
      body: !hasLocation
          ? const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('Location unavailable. GPS module or mobile location integration is required.', textAlign: TextAlign.center)))
          : Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.place),
                  title: Text('${telemetry!.latitude}, ${telemetry.longitude}'),
                  subtitle: Text('Last location update: ${telemetry.createdAt.toLocal()}'),
                ),
                Expanded(
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(target: LatLng(telemetry.latitude!.toDouble(), telemetry.longitude!.toDouble()), zoom: 18),
                    markers: {
                      Marker(
                        markerId: MarkerId(cart.cartId),
                        position: LatLng(telemetry.latitude!.toDouble(), telemetry.longitude!.toDouble()),
                        infoWindow: InfoWindow(title: cart.cartName),
                      ),
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
