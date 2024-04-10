import 'package:get/get.dart';

import '../controllers/latter_controller.dart';

class LatterBinding extends Binding {
  @override
  List<Bind> dependencies() {
    return [
      Bind.lazyPut<LatterController>(
        () => LatterController(),
      ),
    ];
  }
}
