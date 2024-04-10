import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../controllers/latter_controller.dart';

class LatterPage extends GetView<LatterController> {
  const LatterPage({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LatterPage'),
        centerTitle: true,
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
