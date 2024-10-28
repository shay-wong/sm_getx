import 'dart:async';

import '../../../get_core/src/get_interface.dart';

extension LoopEventsExt on GetInterface {
  Future<T> toEnd<T>(FutureOr<T> Function() computation) async {
    await Future.delayed(Duration.zero);
    final val = computation();
    return val;
  }

  /// 允许你尽可能快地执行一个 [computation] 计算或操作，
  /// 但同时提供了通过 [condition] 条件延迟执行的选项.
  /// 例如假设你有一个需要执行的计算密集型任务，但你希望避免在用户交互高峰时（例如滚动列表时）执行，以免影响应用的流畅度。
  /// 你可以设置 condition 来检查当前是否有用户交互，如果有，则延迟执行；否则，立即执行。
  FutureOr<T> asap<T>(T Function() computation,
      {bool Function()? condition}) async {
    T val;
    if (condition == null || !condition()) {
      // 如果 condition == null 或 condition 返回 false,
      // 通过 await Future.delayed(Duration.zero); 将 computation 的执行推迟到下一个事件循环迭代。
      // 这意味着即使是立即执行，也会让出当前的执行上下文，允许微任务（microtask）队列中的任务先执行。
      // 这是利用 Dart 的事件循环和微任务队列的行为来确保 computation 的执行尽可能不阻塞 UI 或其他更高优先级的任务。
      await Future.delayed(Duration.zero);
      val = computation();
    } else {
      val = computation();
    }
    return val;
  }
}
