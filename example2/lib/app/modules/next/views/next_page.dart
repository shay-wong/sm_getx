import 'package:example2/app/routes/app_pages.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/next_controller.dart';

class NextPage extends GetView<NextController> {
  const NextPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NextPage'),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () => Get.toNamed(Routes.latter),
            child: const Text('Latter'),
          ),
        ],
      ),
      body: const Center(
        child: Text(
          'NextPage is working',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
