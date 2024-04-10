import 'package:get/get.dart';

import '../controllers/next_controller.dart';

class NextBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<NextController>(
      () => NextController(),
    );
  }
}
