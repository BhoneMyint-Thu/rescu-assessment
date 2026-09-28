import 'dart:async';

import 'package:get/get.dart';

import '../model/cart_item_model.dart';
import '../model/deal_model.dart';
import '../model/reservation_model.dart';
import '../repository/order_repo.dart';
import '../util/log_service.dart';
import 'api_exception.dart';
import 'clock_service.dart';

/// Owns the bag and its reservations even when its screens are closed.
class CartService extends GetxService {
  final ClockService clock;
  final OrderRepo orderRepo;

  CartService({required this.clock, required this.orderRepo});

  final items = <CartItemModel>[].obs;
  final itemCount = 0.obs;
  final isCheckingOut = false.obs;
  Worker? _expiryWorker;

  bool isReserving(int dealId) =>
      items.firstWhereOrNull((item) => item.deal.id == dealId)?.isReserving ??
      false;

  bool get canCheckout =>
      !isCheckingOut.value &&
      items.isNotEmpty &&
      items.every((item) =>
          !item.isReserving &&
          item.reservation != null &&
          !item.reservation!.isExpiredAt(clock.now) &&
          !item.deal.isFlashSaleExpiredAt(clock.now));

  @override
  void onInit() {
    super.onInit();
    _expiryWorker = ever(clock.time, (_) => removeExpired());
  }

  /// Returns immediately; the pending line is reconciled with the API later.
  bool add(DealModel deal) {
    if (isClosed || isCheckingOut.value) return false;
    final removedExpired = removeExpired();
    if (deal.isFlashSaleExpiredAt(clock.now)) {
      if (!removedExpired) {
        _notice('Flash sale expired',
            '${deal.name} can no longer be added to your bag.');
      }
      return false;
    }

    final existing = items.firstWhereOrNull((item) => item.deal.id == deal.id);
    if (existing?.isReserving ?? false) return false;
    final quantity = (existing?.quantity ?? 0) + 1;
    if (quantity > deal.quantityLeft) {
      _notice('Not enough stock', 'No more of this deal are available.');
      return false;
    }

    final item = existing ?? CartItemModel(deal: deal, isReserving: true);
    if (existing == null) items.add(item);
    unawaited(_reserveQuantity(item, quantity));
    return true;
  }

  Future<void> _reserveQuantity(CartItemModel item, int quantity) async {
    final previous = item.reservation;
    item.reservation = null;
    item.quantity = quantity;
    item.isReserving = true;
    _changed();

    try {
      // The API cannot resize a hold, so release it before reserving again.
      if (previous != null) await orderRepo.releaseReservation(previous.id);
      if (isClosed || !items.contains(item)) return;
      if (item.deal.isFlashSaleExpiredAt(clock.now)) {
        removeExpired();
        return;
      }

      final reservation =
          await orderRepo.reserve(item.deal.id, quantity: quantity);
      // A removed/re-added deal has a different CartItemModel instance.
      if (isClosed || !items.contains(item)) {
        await _release(reservation);
        return;
      }
      item.reservation = reservation;
      item.isReserving = false;
      _changed();
      // A flash sale may have ended while the request was in flight.
      removeExpired();
    } catch (error) {
      LogService.error('reserve deal ${item.deal.id} failed', error);
      if (isClosed || !items.contains(item)) return;
      _removeItem(item);
      _changed();
      _notice(
        'Could not reserve',
        error is ApiException && error.statusCode == 409
            ? '${item.deal.name} could not be reserved because stock changed. '
                'It was removed from your bag. Please try again.'
            : '${item.deal.name} could not be reserved and was removed '
                'from your bag. Please try again.',
      );
    }
  }

  void decrement(int dealId) {
    if (isClosed || isCheckingOut.value) return;
    removeExpired();
    final item = items.firstWhereOrNull((item) => item.deal.id == dealId);
    if (item == null || item.isReserving) return;
    if (item.quantity == 1) {
      remove(dealId);
    } else {
      unawaited(_reserveQuantity(item, item.quantity - 1));
    }
  }

  void remove(int dealId) {
    if (isClosed || isCheckingOut.value) return;
    final item = items.firstWhereOrNull((item) => item.deal.id == dealId);
    if (item == null) return;
    _removeItem(item);
    _changed();
  }

  void _removeItem(CartItemModel item) {
    items.remove(item);
    // Checkout owns these holds until the backend has answered.
    if (!isCheckingOut.value) unawaited(_release(item.reservation));
  }

  /// Runs even when no bag screen is mounted, and when the app resumes.
  bool removeExpired({bool notify = true}) {
    if (isClosed) return false;
    final now = clock.now;
    final expired = items
        .where((item) =>
            item.deal.isFlashSaleExpiredAt(now) ||
            (item.reservation?.isExpiredAt(now) ?? false))
        .toList();
    if (expired.isEmpty) return false;

    for (final item in expired) {
      _removeItem(item);
    }
    _changed();
    if (notify) {
      final flashExpired =
          expired.any((item) => item.deal.isFlashSaleExpiredAt(now));
      _notice(
        flashExpired ? 'Flash sale expired' : 'Reservation expired',
        expired.length == 1
            ? '${expired.single.deal.name} was removed from your bag. '
                'Add it again if it is still available.'
            : '${expired.length} expired items were removed from your bag. '
                'Please review your bag.',
      );
    }
    return true;
  }

  Future<void> checkout() async {
    if (isClosed || isCheckingOut.value) return;
    // Never silently purchase a bag that changed during validation.
    if (removeExpired() || items.isEmpty) return;
    if (!canCheckout) {
      _notice(
          'Still reserving', 'Please wait for your reservations to finish.');
      return;
    }

    final submitted = items.toList(growable: false);
    isCheckingOut.value = true;
    try {
      final order = await orderRepo.checkout(submitted);
      if (isClosed) return;
      // Honor a successful backend response even if local expiry ran meanwhile.
      items.removeWhere(submitted.contains);
      _changed();
      _notice('Order confirmed', 'Order #${order.id} — pick up soon!');
    } catch (error) {
      LogService.error('checkout failed', error);
      if (isClosed) return;
      if (error is ApiException && error.statusCode == 410) {
        final expired = submitted
            .where((item) => item.reservation!.isExpiredAt(clock.now))
            .toList();
        // A 410 can also mean an unknown ID. The API does not identify which
        // one; if no deadline explains it, invalidate all submitted holds.
        for (final item in expired.isEmpty ? submitted : expired) {
          _removeItem(item);
        }
        _changed();
        _notice(
            'Reservation expired',
            'Your order was not placed. Unavailable reservations were removed. '
                'Add those deals again and review your bag before trying checkout.');
      } else {
        _notice('Checkout failed',
            'Your order could not be completed. Please review your bag and try again.');
      }
    } finally {
      removeExpired(notify: false);
      // Includes items removed by expiry while checkout was in flight. Valid
      // items retained after a failed checkout keep their original holds.
      for (final item in submitted) {
        if (isClosed || !items.contains(item)) {
          unawaited(_release(item.reservation));
        }
      }
      if (!isClosed) isCheckingOut.value = false;
    }
  }

  Future<void> _release(ReservationModel? reservation) async {
    if (reservation == null) return;
    try {
      await orderRepo.releaseReservation(reservation.id);
    } catch (error) {
      // A failed cleanup cannot extend the backend's five-minute deadline.
      LogService.error('release reservation ${reservation.id} failed', error);
    }
  }

  num get total => items.fold(0, (sum, item) => sum + item.lineTotal);

  void _changed() {
    items.refresh();
    itemCount.value = items.fold(0, (sum, item) => sum + item.quantity);
  }

  void _notice(String title, String message) {
    Get.snackbar(title, message, snackPosition: SnackPosition.BOTTOM);
  }

  @override
  void onClose() {
    _expiryWorker?.dispose();
    // Submitted holds are cleaned up when checkout returns.
    if (!isCheckingOut.value) {
      for (final item in items) {
        unawaited(_release(item.reservation));
      }
    }
    super.onClose();
  }
}
