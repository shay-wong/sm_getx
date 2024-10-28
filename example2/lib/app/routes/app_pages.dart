import 'package:get/get.dart';

import '../modules/home/bindings/home_binding.dart';
import '../modules/home/views/home_page.dart';
import '../modules/latter/bindings/latter_binding.dart';
import '../modules/latter/views/latter_page.dart';
import '../modules/next/bindings/next_binding.dart';
import '../modules/next/views/next_page.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const initial = Routes.home;

  static final routes = [
    GetPage(
      name: _Paths.home,
      page: () => const HomePage(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: _Paths.next,
      page: () => const NextPage(),
      binding: NextBinding(),
    ),
    GetPage(
      name: _Paths.latter,
      page: () => const LatterPage(),
      binding: LatterBinding(),
    ),
  ];
}
