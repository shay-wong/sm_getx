// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:get/get.dart';

class OtherModel {
  int count;
  OtherModel({
    required this.count,
  });

  @override
  bool operator ==(covariant OtherModel other) {
    if (identical(this, other)) return true;

    return other.count == count;
  }

  @override
  int get hashCode => count.hashCode;

  OtherModel copyWith({
    int? count,
  }) {
    return OtherModel(
      count: count ?? this.count,
    );
  }
}

class NextModel {
  int count;
  OtherModel? otherModel;

  NextModel({
    required this.count,
    this.otherModel,
  });

  @override
  bool operator ==(covariant NextModel other) {
    if (identical(this, other)) return true;

    return other.count == count && other.otherModel == otherModel;
  }

  @override
  int get hashCode => count.hashCode ^ otherModel.hashCode;

  NextModel copyWith({
    int? count,
    OtherModel? otherModel,
  }) {
    return NextModel(
      count: count ?? this.count,
      otherModel: otherModel ?? this.otherModel,
    );
  }
}

class NextController extends GetxController {
  //TODO: Implement NextController

  final count = 0.obs;

  final _nextModel = NextModel(count: 0, otherModel: OtherModel(count: 0)).obs;
  NextModel get nextModel => _nextModel.value;
  set nextModel(NextModel val) => _nextModel.value = val;

  @override
  void onInit() {
    super.onInit();
  }

  void increment() => count.value++;

  void next() {
    _nextModel.update((val) {
      return nextModel..count += 1;
    });

    // _nextModel.updateTo((val) {
    //   val.count += 1;
    //   val.otherModel?.count -= 1;
    // });
  }
}
