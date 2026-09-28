import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app_config.dart';
import '../shared_widget/the_network_image.dart';
import 'cart_controller.dart';
import 'widget/reservation_countdown.dart';

class CartScreen extends GetView<CartController> {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = controller.cartService;
    return Scaffold(
      appBar: AppBar(title: const Text('My bag')),
      body: Obx(() {
        final items = cart.items.toList(growable: false);
        final checkingOut = cart.isCheckingOut.value;
        if (items.isEmpty) {
          return Center(
            child: Text(
                checkingOut ? 'Completing checkout…' : 'Your bag is empty'),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            final busy = item.isReserving || checkingOut;
            return Card(
              key: ValueKey(item.deal.id),
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              color: Colors.white,
              elevation: 0.5,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TheNetworkImage(
                      url: item.deal.imageUrl,
                      width: 64,
                      height: 64,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.deal.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 14.5, fontWeight: FontWeight.w600)),
                          Text(item.deal.storeName,
                              style: TextStyle(
                                  fontSize: 12.5, color: Colors.grey.shade600)),
                          Text('฿${item.deal.price.toStringAsFixed(0)} each',
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: AppConfig.primaryGreen,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          if (item.isReserving)
                            const Text('Reserving…',
                                style:
                                    TextStyle(fontSize: 12, color: Colors.grey))
                          else if (item.reservation != null)
                            ReservationCountdown(
                                expiresAt: item.reservation!.expiresAt),
                          Row(
                            children: [
                              IconButton(
                                tooltip: 'Decrease quantity',
                                visualDensity: VisualDensity.compact,
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: busy
                                    ? null
                                    : () => cart.decrement(item.deal.id),
                              ),
                              Text('${item.quantity}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              IconButton(
                                tooltip: 'Increase quantity',
                                visualDensity: VisualDensity.compact,
                                icon: const Icon(Icons.add_circle_outline),
                                onPressed:
                                    busy ? null : () => cart.add(item.deal),
                              ),
                              const Spacer(),
                              IconButton(
                                tooltip: 'Remove from bag',
                                visualDensity: VisualDensity.compact,
                                icon: const Icon(Icons.delete_outline),
                                onPressed: checkingOut
                                    ? null
                                    : () => cart.remove(item.deal.id),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
      bottomNavigationBar: Obx(() {
        if (cart.items.isEmpty) return const SizedBox.shrink();
        final checkingOut = cart.isCheckingOut.value;
        return Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          color: Colors.white,
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Total', style: TextStyle(fontSize: 13)),
                  Text('฿${cart.total.toStringAsFixed(0)}',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(width: 24),
              Expanded(
                child: FilledButton(
                  onPressed: cart.canCheckout ? controller.checkout : null,
                  child: checkingOut
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Checkout'),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
