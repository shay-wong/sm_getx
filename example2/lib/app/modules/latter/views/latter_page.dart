import 'package:example2/app/routes/app_pages.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/latter_controller.dart';

class LatterPage extends GetView<LatterController> {
  const LatterPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LatterPage'),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () => Get.until(
              (p0) => p0.name == Routes.home,
            ),
            child: const Text('BackUntil'),
          ),
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Close'),
          ),
        ],
      ),
      body: const Center(
        child: Text(
          'LatterPage is working',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
