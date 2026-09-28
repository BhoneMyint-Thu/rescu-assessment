import 'package:get/get.dart';

import '../../service/cart_service.dart';

class CartController extends GetxController {
  final CartService cartService;

  CartController({required this.cartService});

  Future<void> checkout() => cartService.checkout();
}
