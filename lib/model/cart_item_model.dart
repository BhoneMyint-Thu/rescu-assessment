import 'deal_model.dart';
import 'reservation_model.dart';

class CartItemModel {
  final DealModel deal;
  int quantity;

  /// Null while the requested quantity is being reserved.
  ReservationModel? reservation;
  bool isReserving;

  CartItemModel({
    required this.deal,
    this.quantity = 1,
    this.reservation,
    this.isReserving = false,
  });

  num get lineTotal => deal.price * quantity;
}
