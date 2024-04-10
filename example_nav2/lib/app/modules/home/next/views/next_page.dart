import 'package:example_nav2/app/routes/app_pages.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/next_controller.dart';

class NextPage extends GetView<NextController> {
  const NextPage({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return GetRouterOutlet.builder(
      route: Routes.next,
      builder: (BuildContext context) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('NextPage'),
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_outlined),
              onPressed: () {
                Get.back();
              },
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Get.toNamed(Routes.latter);
                },
                child: const Text('Latter'),
              ),
              TextButton(
                onPressed: () {
                  Get.toNamed(Routes.homeLatter);
                },
                child: const Text('Home Latter'),
              )
            ],
          ),
          body: Center(
            child: Obx(
              () => Text(
                'NextPage is working ${controller.nextModel.count} ${controller.nextModel.otherModel?.count}',
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              // controller.increment();
              controller.next();
            },
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}
