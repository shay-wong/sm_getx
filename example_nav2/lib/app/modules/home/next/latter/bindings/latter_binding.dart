import 'package:get/get.dart';

import '../controllers/latter_controller.dart';

class LatterBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LatterController>(
      () => LatterController(),
    );
  }
}
