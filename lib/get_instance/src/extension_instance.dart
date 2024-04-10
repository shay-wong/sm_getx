import 'dart:async';

import 'package:flutter/material.dart';

import '../../get_core/get_core.dart';
import '../../get_navigation/src/router_report.dart';
import 'lifecycle.dart';

class InstanceInfo {
  final bool? isPermanent;
  final bool? isSingleton;
  bool get isCreate => !isSingleton!;
  final bool isRegistered;
  final bool isPrepared;
  final bool? isInit;
  const InstanceInfo({
    required this.isPermanent,
    required this.isSingleton,
    required this.isRegistered,
    required this.isPrepared,
    required this.isInit,
  });

  @override
  String toString() {
    return 'InstanceInfo(isPermanent: $isPermanent, isSingleton: $isSingleton, isRegistered: $isRegistered, isPrepared: $isPrepared, isInit: $isInit)';
  }
}

extension ResetInstance on GetInterface {
  /// Clears all registered instances (and/or tags).
  /// Even the persistent ones.
  /// This should be used at the end or tearDown of unit tests.
  ///
  /// `clearFactory` clears the callbacks registered by [lazyPut]
  /// `clearRouteBindings` clears Instances associated with routes.
  ///
  bool resetInstance({bool clearRouteBindings = true}) {
    //  if (clearFactory) _factory.clear();
    // deleteAll(force: true);
    if (clearRouteBindings) RouterReportManager.instance.clearRouteKeys();
    Inst._singl.clear();

    return true;
  }
}

extension Inst on GetInterface {
  T call<T>() => find<T>();

  /// Holds references to every registered Instance when using
  /// `Get.put()`
  /// 使用 'Get.put()'时，保存对每个注册实例的引用
  static final Map<String, _InstanceBuilderFactory> _singl = {};

  /// Holds a reference to every registered callback when using
  /// `Get.lazyPut()`
  // static final Map<String, _Lazy> _factory = {};

  // void injector<S>(
  //   InjectorBuilderCallback<S> fn, {
  //   String? tag,
  //   bool fenix = false,
  //   //  bool permanent = false,
  // }) {
  //   lazyPut(
  //     () => fn(this),
  //     tag: tag,
  //     fenix: fenix,
  //     // permanent: permanent,
  //   );
  // }

  S put<S>(
    S dependency, {
    String? tag,
    bool permanent = false,
  }) {
    _insert(
      isSingleton: true,
      name: tag,
      permanent: permanent,
      builder: (() => dependency),
    );
    return find<S>(tag: tag);
  }

  /// Creates a new Instance<S> lazily from the `<S>builder()` callback.
  ///
  /// The first time you call `Get.find()`, the `builder()` callback will create
  /// the Instance and persisted as a Singleton (like you would
  /// use `Get.put()`).
  ///
  /// Using `Get.smartManagement` as [SmartManagement.keepFactory] has
  /// the same outcome as using `fenix:true` :
  /// The internal register of `builder()` will remain in memory to recreate
  /// the Instance if the Instance has been removed with `Get.delete()`.
  /// Therefore, future calls to `Get.find()` will return the same Instance.
  ///
  /// If you need to make use of GetxController's life-cycle
  /// (`onInit(), onStart(), onClose()`) [fenix] is a great choice to mix with
  /// `GetBuilder()` and `GetX()` widgets, and/or `GetMaterialApp` Navigation.
  ///
  /// You could use `Get.lazyPut(fenix:true)` in your app's `main()` instead
  /// of `Bindings()` for each `GetPage`.
  /// And the memory management will be similar.
  ///
  /// Subsequent calls to `Get.lazyPut()` with the same parameters
  /// (<[S]> and optionally [tag] will **not** override the original).
  /// ? [fenix] 是否需要重新创建实例
  void lazyPut<S>(
    InstanceBuilderCallback<S> builder, {
    String? tag,
    bool? fenix,
    bool permanent = false,
  }) {
    _insert(
      isSingleton: true,
      name: tag,
      permanent: permanent,
      builder: builder,
      fenix: fenix ?? Get.smartManagement == SmartManagement.keepFactory,
    );
  }

  /// Creates a new Class Instance [S] from the builder callback[S].
  /// Every time [find]<[S]>() is used, it calls the builder method to generate
  /// a new Instance [S].
  /// It also registers each `instance.onClose()` with the current
  /// Route `Get.reference` to keep the lifecycle active.
  /// Is important to know that the instances created are only stored per Route.
  /// So, if you call `Get.delete<T>()` the "instance factory" used in this
  /// method (`Get.spawn<T>()`) will be removed, but NOT the instances
  /// already created by it.
  ///
  /// Example:
  ///
  /// ```Get.spawn(() => Repl());
  /// Repl a = find();
  /// Repl b = find();
  /// print(a==b); (false)```
  void spawn<S>(
    InstanceBuilderCallback<S> builder, {
    String? tag,
    bool permanent = true,
  }) {
    _insert(
      isSingleton: false,
      name: tag,
      builder: builder,
      permanent: permanent,
    );
  }

  /// Injects the Instance [S] builder into the `_singleton` HashMap.
  /// 将实例构建器注入到 [_singl] HashMap
  /// [builder] 里通常就是 [Controller] 的初始化方法
  void _insert<S>({
    bool? isSingleton,
    String? name,
    bool permanent = false,
    required InstanceBuilderCallback<S> builder,
    bool fenix = false,
  }) {
    // 根据类型和 tag 生成 key
    final key = _getKey(S, name);

    _InstanceBuilderFactory<S>? dep;
    // 判断 [_singl] 中是否存在该 key
    if (_singl.containsKey(key)) {
      final newDep = _singl[key];
      // 判断该 key 对应的实例是否为脏实例
      if (newDep == null || !newDep.isDirty) {
        return;
      } else {
        // 如果是脏实例则将其移除
        dep = newDep as _InstanceBuilderFactory<S>;
      }
    }
    // 生成新的实例, 并将其注册到 [_singl] 中
    _singl[key] = _InstanceBuilderFactory<S>(
      isSingleton: isSingleton,
      builderFunc: builder,
      permanent: permanent,
      isInit: false,
      fenix: fenix,
      tag: name,
      lateRemove: dep, // ? 如果存在 dep 则会在稍后被移除
    );
  }

  /// Initializes the dependencies for a Class Instance [S] (or tag),
  /// If its a Controller, it starts the lifecycle process.
  /// Optionally associating the current Route to the lifetime of the instance,
  /// if `Get.smartManagement` is marked as [SmartManagement.full] or
  /// [SmartManagement.keepFactory]
  /// Only flags `isInit` if it's using `Get.create()`
  /// (not for Singletons access).
  /// Returns the instance if not initialized, required for Get.create() to
  /// work properly.
  /// 初始化类实例 [S]（或 [tag]）的依赖项，
  /// 如果它是控制器 [GetLifeCycleMixin]，则启动生命周期进程.
  /// 如果 `Get.smartManagement` 标记为 [SmartManagement.full] 或 [SmartManagement.keepFactory],
  /// 则可选择将当前路由与实例的生命周期关联。
  /// 如果使用 `Get.create()` 创建，则仅标记 `isInit`（不适用于单例访问）.
  /// 如果未初始化，则返回 Get.create() 所必需的实例。
  S? _initDependencies<S>({String? name}) {
    // 根据类型和 tag 生成 key
    final key = _getKey(S, name);
    // 因为前面 [find] 已经判断过 _singl 中是否存在该 key
    // 所以这里不需要再判断, 直接从 [_singl] 中取值即可
    final isInit = _singl[key]!.isInit;
    S? i;
    if (!isInit) {
      // 如果未初始化过, 判断是否是单例
      final isSingleton = _singl[key]?.isSingleton ?? false;
      if (isSingleton) {
        // 如果是单例则将其设置为已初始化
        _singl[key]!.isInit = true;
      }
      // 得到调用 [getDependency] 以获取的实例
      i = _startController<S>(tag: name);

      if (isSingleton) {
        if (Get.smartManagement != SmartManagement.onlyBuilder) {
          // 如果是单例且不是 [onlyBuilder] 的模式, 将实例绑定到当前路由
          RouterReportManager.instance.reportDependencyLinkedToRoute(_getKey(S, name));
        }
      }
    }
    return i;
  }

  InstanceInfo getInstanceInfo<S>({String? tag}) {
    final build = _getDependency<S>(tag: tag);

    return InstanceInfo(
      isPermanent: build?.permanent,
      isSingleton: build?.isSingleton,
      isRegistered: isRegistered<S>(tag: tag),
      isPrepared: !(build?.isInit ?? true),
      isInit: build?.isInit,
    );
  }

  _InstanceBuilderFactory? _getDependency<S>({String? tag, String? key}) {
    final newKey = key ?? _getKey(S, tag);

    if (!_singl.containsKey(newKey)) {
      Get.log('Instance "$newKey" is not registered.', isError: true);
      return null;
    } else {
      return _singl[newKey];
    }
  }

  void markAsDirty<S>({String? tag, String? key}) {
    final newKey = key ?? _getKey(S, tag);
    if (_singl.containsKey(newKey)) {
      final dep = _singl[newKey];
      if (dep != null && !dep.permanent) {
        dep.isDirty = true;
      }
    }
  }

  /// Initializes the controller
  /// 初始化控制器
  S _startController<S>({String? tag}) {
    // 根据类型和 tag 生成 key
    final key = _getKey(S, tag);
    // 调用 [getDependency] 以获取对应的实例
    final i = _singl[key]!.getDependency() as S;
    // 如果是 [GetLifeCycleMixin] 类型, 则调用其 [onStart] 方法, 开始生命周期回调.
    if (i is GetLifeCycleMixin) {
      i.onStart();
      if (tag == null) {
        Get.log('Instance "$S" has been initialized');
      } else {
        Get.log('Instance "$S" with tag "$tag" has been initialized');
      }
      if (!_singl[key]!.isSingleton!) {
        // 如果不是单例, 保存实例的 onClose() 引用
        RouterReportManager.instance.appendRouteByCreate(i);
      }
    }
    return i;
  }

  S putOrFind<S>(InstanceBuilderCallback<S> dep, {String? tag}) {
    final key = _getKey(S, tag);

    if (_singl.containsKey(key)) {
      return _singl[key]!.getDependency() as S;
    } else {
      return put(dep(), tag: tag);
    }
  }

  /// Finds the registered type <[S]> (or [tag])
  /// In case of using Get.[create] to register a type <[S]> or [tag],
  /// it will create an instance each time you call [find].
  /// If the registered type <[S]> (or [tag]) is a Controller,
  /// it will initialize it's lifecycle.
  /// 查找已注册的类型 <[S]> (或 [tag])
  /// 如果使用 Get.[create] 注册类型 <[S]> 或 [tag],
  /// 每次调用 [find] 时，它都会创建一个实例.
  /// 如果已注册的类型 <[S]> (或 [tag]) 是控制器，它将初始化其生命周期。
  S find<S>({String? tag}) {
    // 根据类型和 tag 生成唯一 key
    final key = _getKey(S, tag);
    // 如果已经注册过
    if (isRegistered<S>(tag: tag)) {
      // 取出对应的实例
      final dep = _singl[key];
      // 如果实例为空, 抛出异常
      if (dep == null) {
        if (tag == null) {
          throw 'Class "$S" is not registered';
        } else {
          throw 'Class "$S" with tag "$tag" is not registered';
        }
      }

      /// although dirty solution, the lifecycle starts inside
      /// `initDependencies`, so we have to return the instance from there
      /// to make it compatible with `Get.create()`.
      /// 虽然是 dirty 的解决方案，但生命周期是在  `initDependencies` 内部开始的,
      /// 因此我们必须从那里返回实例，以便使其与 `Get.create()` 兼容.
      final i = _initDependencies<S>(name: tag);
      return i ?? dep.getDependency() as S;
    } else {
      // 如果没有注册过, 抛出异常
      // ignore: lines_longer_than_80_chars
      throw '"$S" not found. You need to call "Get.put($S())" or "Get.lazyPut(()=>$S())"';
    }
  }

  /// The findOrNull method will return the instance if it is registered;
  /// otherwise, it will return null.
  /// 如果已注册，则 [findOrNull] 方法将返回该实例;
  /// 否则，它将返回 null.
  S? findOrNull<S>({String? tag}) {
    if (isRegistered<S>(tag: tag)) {
      return find<S>(tag: tag);
    }
    return null;
  }

  /// Replace a parent instance of a class in dependency management
  /// with a [child] instance
  /// - [tag] optional, if you use a [tag] to register the Instance.
  void replace<P>(P child, {String? tag}) {
    final info = getInstanceInfo<P>(tag: tag);
    final permanent = (info.isPermanent ?? false);
    delete<P>(tag: tag, force: permanent);
    put(child, tag: tag, permanent: permanent);
  }

  /// Replaces a parent instance with a new Instance<P> lazily from the
  /// `<P>builder()` callback.
  /// - [tag] optional, if you use a [tag] to register the Instance.
  /// - [fenix] optional
  ///
  ///  Note: if fenix is not provided it will be set to true if
  /// the parent instance was permanent
  void lazyReplace<P>(InstanceBuilderCallback<P> builder, {String? tag, bool? fenix}) {
    final info = getInstanceInfo<P>(tag: tag);
    final permanent = (info.isPermanent ?? false);
    delete<P>(tag: tag, force: permanent);
    lazyPut(builder, tag: tag, fenix: fenix ?? permanent);
  }

  /// Generates the key based on [type] (and optionally a [name])
  /// to register an Instance Builder in the hashmap.
  /// 基于 [type] (以及可选的 [name]) 生成唯一 [key]，以便在 [_singl] HashMap 中注册实例构建器。
  String _getKey(Type type, String? name) {
    return name == null ? type.toString() : type.toString() + name;
  }

  /// Delete registered Class Instance [S] (or [tag]) and, closes any open
  /// controllers `DisposableInterface`, cleans up the memory
  ///
  /// /// Deletes the Instance<[S]>, cleaning the memory.
  //  ///
  //  /// - [tag] Optional "tag" used to register the Instance
  //  /// - [key] For internal usage, is the processed key used to register
  //  ///   the Instance. **don't use** it unless you know what you are doing.

  /// Deletes the Instance<[S]>, cleaning the memory and closes any open
  /// controllers (`DisposableInterface`).
  ///
  /// - [tag] Optional "tag" used to register the Instance
  /// - [key] For internal usage, is the processed key used to register
  ///   the Instance. **don't use** it unless you know what you are doing.
  /// - [force] Will delete an Instance even if marked as `permanent`.
  bool delete<S>({String? tag, String? key, bool force = false}) {
    final newKey = key ?? _getKey(S, tag);

    if (!_singl.containsKey(newKey)) {
      Get.log('Instance "$newKey" already removed.', isError: true);
      return false;
    }

    final dep = _singl[newKey];

    if (dep == null) return false;

    final _InstanceBuilderFactory builder;
    if (dep.isDirty) {
      builder = dep.lateRemove ?? dep;
    } else {
      builder = dep;
    }

    if (builder.permanent && !force) {
      Get.log(
        // ignore: lines_longer_than_80_chars
        '"$newKey" has been marked as permanent, SmartManagement is not authorized to delete it.',
        isError: true,
      );
      return false;
    }
    final i = builder.dependency;

    if (i is GetxServiceMixin && !force) {
      return false;
    }

    if (i is GetLifeCycleMixin) {
      i.onDelete();
      Get.log('"$newKey" onDelete() called');
    }

    if (builder.fenix) {
      builder.dependency = null;
      builder.isInit = false;
      return true;
    } else {
      if (dep.lateRemove != null) {
        dep.lateRemove = null;
        Get.log('"$newKey" deleted from memory');
        return false;
      } else {
        _singl.remove(newKey);
        if (_singl.containsKey(newKey)) {
          Get.log('Error removing object "$newKey"', isError: true);
        } else {
          Get.log('"$newKey" deleted from memory');
        }
        return true;
      }
    }
  }

  /// Delete all registered Class Instances and, closes any open
  /// controllers `DisposableInterface`, cleans up the memory
  ///
  /// - [force] Will delete the Instances even if marked as `permanent`.
  void deleteAll({bool force = false}) {
    final keys = _singl.keys.toList();
    for (final key in keys) {
      delete(key: key, force: force);
    }
  }

  void reloadAll({bool force = false}) {
    _singl.forEach((key, value) {
      if (value.permanent && !force) {
        Get.log('Instance "$key" is permanent. Skipping reload');
      } else {
        value.dependency = null;
        value.isInit = false;
        Get.log('Instance "$key" was reloaded.');
      }
    });
  }

  void reload<S>({
    String? tag,
    String? key,
    bool force = false,
  }) {
    final newKey = key ?? _getKey(S, tag);

    final builder = _getDependency<S>(tag: tag, key: newKey);
    if (builder == null) return;

    if (builder.permanent && !force) {
      Get.log(
        '''Instance "$newKey" is permanent. Use [force = true] to force the restart.''',
        isError: true,
      );
      return;
    }

    final i = builder.dependency;

    if (i is GetxServiceMixin && !force) {
      return;
    }

    if (i is GetLifeCycleMixin) {
      i.onDelete();
      Get.log('"$newKey" onDelete() called');
    }

    builder.dependency = null;
    builder.isInit = false;
    Get.log('Instance "$newKey" was restarted.');
  }

  /// Check if a Class Instance<[S]> (or [tag]) is registered in memory.
  /// - [tag] is optional, if you used a [tag] to register the Instance.
  bool isRegistered<S>({String? tag}) => _singl.containsKey(_getKey(S, tag));

  /// Checks if a lazy factory callback `Get.lazyPut()` that returns an
  /// Instance<[S]> is registered in memory.
  /// - [tag] is optional, if you used a [tag] to register the lazy Instance.
  bool isPrepared<S>({String? tag}) {
    final newKey = _getKey(S, tag);

    final builder = _getDependency<S>(tag: tag, key: newKey);
    if (builder == null) {
      return false;
    }

    if (!builder.isInit) {
      return true;
    }
    return false;
  }
}

typedef InstanceBuilderCallback<S> = S Function();

typedef InstanceCreateBuilderCallback<S> = S Function(BuildContext _);

// typedef InstanceBuilderCallback<S> = S Function();

// typedef InjectorBuilderCallback<S> = S Function(Inst);

typedef AsyncInstanceBuilderCallback<S> = Future<S> Function();

/// Internal class to register instances with `Get.put<S>()`.
class _InstanceBuilderFactory<S> {
  /// Marks the Builder as a single instance.
  /// For reusing [dependency] instead of [builderFunc]
  bool? isSingleton;

  /// When fenix mode is available, when a new instance is need
  /// Instance manager will recreate a new instance of S
  /// 当 [fenix]=true 时，每当需要新实例时，实例管理器将重新创建 [S] 的新实例.
  bool fenix;

  /// Stores the actual object instance when [isSingleton]=true.
  /// [isSingleton]=true 时, 用来存储实际对象实例。
  S? dependency;

  /// Generates (and regenerates) the instance when [isSingleton]=false.
  /// Usually used by factory methods
  /// 当 [isSingleton]=false 时生成（或重新生成）实例.
  /// 通常用于工厂方法
  /// 这里保存的通常就是 Controller 的初始化方法
  InstanceBuilderCallback<S> builderFunc;

  /// Flag to persist the instance in memory,
  /// without considering `Get.smartManagement`
  bool permanent = false;

  bool isInit = false;

  _InstanceBuilderFactory<S>? lateRemove;

  bool isDirty = false;

  String? tag;

  _InstanceBuilderFactory({
    required this.isSingleton,
    required this.builderFunc,
    required this.permanent,
    required this.isInit,
    required this.fenix,
    required this.tag,
    required this.lateRemove,
  });

  void _showInitLog() {
    if (tag == null) {
      Get.log('Instance "$S" has been created');
    } else {
      Get.log('Instance "$S" has been created with tag "$tag"');
    }
  }

  /// Gets the actual instance by it's [builderFunc] or the persisted instance.
  /// 通过 [builderFunc] 或持久化实例获取实际的实例.
  S getDependency() {
    if (isSingleton!) {
      if (dependency == null) {
        // 如果是单例，且 [dependency] 为空，则调用 [builderFunc] 重新生成一个实例
        _showInitLog();
        dependency = builderFunc();
      }
      return dependency!;
    } else {
      // 如果不是单例，则调用 [builderFunc] 生成一个实例
      return builderFunc();
    }
  }
}
