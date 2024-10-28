import 'package:get/get.dart';

import '../controllers/next_controller.dart';

class NextBinding extends Binding {
  @override
  List<Bind> dependencies() {
    return [
      Bind.lazyPut<NextController>(
        () => NextController(),
      ),
    ];
  }
}
