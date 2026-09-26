import 'package:get/get.dart';

import '../model/cart_item_model.dart';
import '../model/deal_model.dart';
import '../util/log_service.dart';
import 'clock_service.dart';

/// App-wide cart. Lives for the whole session.
///
/// NOTE: the starter cart is purely local — it does not reserve stock on the
/// backend. See the "Reservations" feature task in PROBLEM.md.
class CartService extends GetxService {
  final ClockService clock;

  CartService({required this.clock});

  final items = <CartItemModel>[].obs;
  final itemCount = 0.obs;
  Worker? _expiryWorker;

  @override
  void onInit() {
    super.onInit();
    _expiryWorker = ever(clock.time, (_) => removeExpired());
  }

  bool add(DealModel deal) {
    if (deal.isFlashSaleExpiredAt(clock.now)) {
      if (!removeExpired()) {
        Get.snackbar(
          'Flash sale expired',
          '${deal.name} can no longer be added to your bag.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
      return false;
    }

    final existing = items.firstWhereOrNull((i) => i.deal.id == deal.id);
    if (existing != null) {
      if (existing.quantity >= deal.quantityLeft) {
        LogService.log('cart: cannot add more of deal ${deal.id}');
        return false;
      }
      existing.quantity++;
      items.refresh();
    } else {
      items.add(CartItemModel(deal: deal));
    }
    _recount();
    return true;
  }

  /// Runs even when no deal cards or bag screen are mounted.
  bool removeExpired() {
    final now = clock.now;
    final expired =
        items.where((item) => item.deal.isFlashSaleExpiredAt(now)).toList();
    if (expired.isEmpty) return false;

    items.removeWhere((item) => item.deal.isFlashSaleExpiredAt(now));
    _recount();
    Get.snackbar(
      'Flash sale expired',
      expired.length == 1
          ? '${expired.single.deal.name} was removed from your bag.'
          : '${expired.length} expired deals were removed from your bag.',
      snackPosition: SnackPosition.BOTTOM,
    );
    return true;
  }

  void decrement(int dealId) {
    final existing = items.firstWhereOrNull((i) => i.deal.id == dealId);
    if (existing == null) return;
    existing.quantity--;
    if (existing.quantity <= 0) {
      items.removeWhere((i) => i.deal.id == dealId);
    } else {
      items.refresh();
    }
    _recount();
  }

  void remove(int dealId) {
    items.removeWhere((i) => i.deal.id == dealId);
    _recount();
  }

  void clear() {
    items.clear();
    _recount();
  }

  num get total => items.fold(0, (sum, i) => sum + i.lineTotal);

  void _recount() {
    itemCount.value = items.fold(0, (sum, i) => sum + i.quantity);
  }

  @override
  void onClose() {
    _expiryWorker?.dispose();
    super.onClose();
  }
}
