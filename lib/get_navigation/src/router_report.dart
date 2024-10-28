import 'dart:collection';

import '../../get.dart';

class RouterReportManager<T> {
  /// Holds a reference to `Get.reference` when the Instance was
  /// created to manage the memory.
  /// 路由和实例的绑定关系,
  /// 保存实例的引用，用于管理内存. key 是路由，List 中存的是实例的 key
  final Map<T?, List<String>> _routesKey = {};

  /// Stores the onClose() references of instances created with `Get.create()`
  /// using the `Get.reference`.
  /// Experimental feature to keep the lifecycle and memory management with
  /// non-singleton instances.
  /// 使用 `Get.reference` 存储使用 `Get.create()` 创建的实例的 onClose() 引用。
  /// 实验性功能，用于保持非单例实例的生命周期和内存管理。
  final Map<T?, HashSet<Function>> _routesByCreate = {};

  static RouterReportManager? _instance;

  RouterReportManager._();

  static RouterReportManager get instance =>
      _instance ??= RouterReportManager._();

  static void dispose() {
    _instance = null;
  }

  void printInstanceStack() {
    Get.log(_routesKey.toString());
  }

  /// 当前路由
  T? _current;

  /// 保存当前路由
  // ignore: use_setters_to_change_properties
  void reportCurrentRoute(T newRoute) {
    _current = newRoute;
  }

  /// Links a Class instance [S] (or [tag]) to the current route.
  /// Requires usage of `GetMaterialApp`.
  /// 将类实例 [S]（或 [tag]）绑定到当前路由.
  /// 需要使用 [GetMaterialApp].
  void reportDependencyLinkedToRoute(String dependencyKey) {
    // 如果没有当前路由，则返回
    if (_current == null) return;
    // 绑定关系
    if (_routesKey.containsKey(_current)) {
      _routesKey[_current!]!.add(dependencyKey);
    } else {
      _routesKey[_current] = <String>[dependencyKey];
    }
  }

  void clearRouteKeys() {
    _routesKey.clear();
    _routesByCreate.clear();
  }

  void appendRouteByCreate(GetLifeCycleMixin i) {
    _routesByCreate[_current] ??= HashSet<Function>();
    // _routesByCreate[Get.reference]!.add(i.onDelete as Function);
    _routesByCreate[_current]!.add(i.onDelete);
  }

  void reportRouteDispose(T disposed) {
    if (Get.smartManagement != SmartManagement.onlyBuilder) {
      // ambiguate(Engine.instance)!.addPostFrameCallback((_) {
      // Future.microtask(() {
      _removeDependencyByRoute(disposed);
      // });
    }
  }

  void reportRouteWillDispose(T disposed) {
    final keysToRemove = <String>[];

    _routesKey[disposed]?.forEach(keysToRemove.add);

    /// Removes `Get.create()` instances registered in `routeName`.
    if (_routesByCreate.containsKey(disposed)) {
      for (final onClose in _routesByCreate[disposed]!) {
        // assure the [DisposableInterface] instance holding a reference
        // to onClose() wasn't disposed.
        onClose();
      }
      _routesByCreate[disposed]!.clear();
      _routesByCreate.remove(disposed);
    }

    for (final element in keysToRemove) {
      Get.markAsDirty(key: element);

      //_routesKey.remove(element);
    }

    keysToRemove.clear();
  }

  /// Clears from memory registered Instances associated with [routeName] when
  /// using `Get.smartManagement` as [SmartManagement.full] or
  /// [SmartManagement.keepFactory]
  /// Meant for internal usage of `GetPageRoute` and `GetDialogRoute`
  void _removeDependencyByRoute(T routeName) {
    final keysToRemove = <String>[];

    _routesKey[routeName]?.forEach(keysToRemove.add);

    /// Removes `Get.create()` instances registered in `routeName`.
    if (_routesByCreate.containsKey(routeName)) {
      for (final onClose in _routesByCreate[routeName]!) {
        // assure the [DisposableInterface] instance holding a reference
        // to onClose() wasn't disposed.
        onClose();
      }
      _routesByCreate[routeName]!.clear();
      _routesByCreate.remove(routeName);
    }

    for (final element in keysToRemove) {
      final value = Get.delete(key: element);
      if (value) {
        _routesKey[routeName]?.remove(element);
      }
    }

    _routesKey.remove(routeName);

    keysToRemove.clear();
  }
}
