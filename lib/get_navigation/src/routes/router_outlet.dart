import 'package:flutter/material.dart';

import '../../../get.dart';

class RouterOutlet<TDelegate extends RouterDelegate<T>, T extends Object> extends StatefulWidget {
  final TDelegate routerDelegate;
  final Widget Function(BuildContext context) builder;

  RouterOutlet.builder({
    super.key,
    TDelegate? delegate,
    required this.builder,
  }) : routerDelegate = delegate ?? Get.delegate<TDelegate, T>()!;

  RouterOutlet({
    Key? key,
    TDelegate? delegate,
    required Iterable<GetPage> Function(T currentNavStack) pickPages,
    required Widget Function(
      BuildContext context,
      TDelegate,
      Iterable<GetPage>? page,
    ) pageBuilder,
  }) : this.builder(
            builder: (context) {
              final currentConfig = context.delegate.currentConfiguration as T?;
              final rDelegate = context.delegate as TDelegate;
              var picked = currentConfig == null ? null : pickPages(currentConfig);
              if (picked?.isEmpty ?? true) {
                picked = null;
              }
              return pageBuilder(context, rDelegate, picked);
            },
            delegate: delegate,
            key: key);
  @override
  RouterOutletState<TDelegate, T> createState() => RouterOutletState<TDelegate, T>();
}

class RouterOutletState<TDelegate extends RouterDelegate<T>, T extends Object>
    extends State<RouterOutlet<TDelegate, T>> {
  RouterDelegate? delegate;
  late ChildBackButtonDispatcher _backButtonDispatcher;

  void _listener() {
    setState(() {});
  }

  VoidCallback? disposer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    disposer?.call();
    final router = Router.of(context);
    delegate ??= router.routerDelegate;
    delegate?.addListener(_listener);
    disposer = () => delegate?.removeListener(_listener);

    _backButtonDispatcher = router.backButtonDispatcher!.createChildBackButtonDispatcher();
  }

  @override
  void dispose() {
    super.dispose();
    disposer?.call();
  }

  @override
  Widget build(BuildContext context) {
    _backButtonDispatcher.takePriority();
    return widget.builder(context);
  }
}

class GetRouterOutlet extends RouterOutlet<GetDelegate, RouteDecoder> {
  GetRouterOutlet({
    Key? key,
    String? anchorRoute,
    required String initialRoute,
    Iterable<GetPage> Function(Iterable<GetPage> afterAnchor)? filterPages,
    GetDelegate? delegate,
    String? restorationScopeId,
  }) : this.pickPages(
          restorationScopeId: restorationScopeId,
          pickPages: (config) {
            Iterable<GetPage<dynamic>> ret;
            if (anchorRoute == null) {
              // jump the ancestor path
              final length = Uri.parse(initialRoute).pathSegments.length;

              return config.currentTreeBranch.skip(length).take(length).toList();
            }
            ret = config.currentTreeBranch.pickAfterRoute(anchorRoute);
            if (filterPages != null) {
              ret = filterPages(ret);
            }
            return ret;
          },
          key: key,
          emptyPage: (delegate) => delegate.matchRoute(initialRoute).route ?? delegate.notFoundRoute,
          navigatorKey: Get.nestedKey(anchorRoute)?.navigatorKey,
          delegate: delegate,
        );
  GetRouterOutlet.pickPages({
    super.key,
    Widget Function(GetDelegate delegate)? emptyWidget,
    GetPage Function(GetDelegate delegate)? emptyPage,
    required super.pickPages,
    bool Function(Route<dynamic>, dynamic)? onPopPage,
    String? restorationScopeId,
    GlobalKey<NavigatorState>? navigatorKey,
    GetDelegate? delegate,
  }) : super(
          pageBuilder: (context, rDelegate, pages) {
            final pageRes = <GetPage?>[
              ...?pages,
              if (pages == null || pages.isEmpty) emptyPage?.call(rDelegate),
            ].whereType<GetPage>();

            if (pageRes.isNotEmpty) {
              return InheritedNavigator(
                navigatorKey: navigatorKey ?? Get.rootController.rootDelegate.navigatorKey,
                child: GetNavigator(
                  restorationScopeId: restorationScopeId,
                  onPopPage: onPopPage ??
                      (route, result) {
                        final didPop = route.didPop(result);
                        if (!didPop) {
                          return false;
                        }
                        return true;
                      },
                  pages: pageRes.toList(),
                  key: navigatorKey,
                ),
              );
            }
            return (emptyWidget?.call(rDelegate) ?? const SizedBox.shrink());
          },
          delegate: delegate ?? Get.rootController.rootDelegate,
        );

  GetRouterOutlet.builder({
    super.key,
    required super.builder,
    String? route,
    GetDelegate? routerDelegate,
  }) : super.builder(
          delegate: routerDelegate ?? (route != null ? Get.nestedKey(route) : Get.rootController.rootDelegate),
        );
}

class InheritedNavigator extends InheritedWidget {
  const InheritedNavigator({
    super.key,
    required super.child,
    required this.navigatorKey,
  });
  final GlobalKey<NavigatorState> navigatorKey;

  static InheritedNavigator? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<InheritedNavigator>();
  }

  @override
  bool updateShouldNotify(InheritedNavigator oldWidget) {
    return true;
  }
}

extension NavKeyExt on BuildContext {
  GlobalKey<NavigatorState>? get parentNavigatorKey {
    return InheritedNavigator.of(this)?.navigatorKey;
  }
}

extension PagesListExt on List<GetPage> {
  /// Returns the route and all following routes after the given route.
  /// 返回路由栈中传入的 [route] 以及该 [route] 之后的所有后续路由。
  Iterable<GetPage> pickFromRoute(String route) {
    return skipWhile((value) => value.name != route);
  }

  /// Returns the routes after the given route.
  /// 返回路由栈中传入的 [route] 之后的路由。
  Iterable<GetPage> pickAfterRoute(String route) {
    // If the provided route is root, we take the first route after root.
    // 如果传入的路由是根路由，我们取根路由之后的第一个路由。
    if (route == '/') {
      return pickFromRoute(route).skip(1).take(1);
    }
    // Otherwise, we skip the route and take all routes after it.
    // 否则，我们跳过传入的路由，取传入的路由之后的所有路由。
    return pickFromRoute(route).skip(1);
  }
}

typedef NavigatorItemBuilderBuilder = Widget Function(BuildContext context, List<String> routes, int index);

/// 这个类接受一个路由列表和一个构建方法，基于当前路由返回对应的 [Widget]。
class IndexedRouteBuilder<T> extends StatelessWidget {
  const IndexedRouteBuilder({
    super.key,
    required this.builder,
    required this.routes,
  });

  /// 路由列表，每个元素是一个字符串，代表应用中的一个路由。
  final List<String> routes;

  /// 构建函数类型定义，接受当前上下文 [BuildContext]、路由列表 [routes] 和当前路由的索引 [index]，返回一个 [Widget]。
  final NavigatorItemBuilderBuilder builder;

  // Method to get the current index based on the route
  /// 根据当前的路由 [currentLocation]（即页面位置）来确定其在路由列表中的索引。
  /// 如果当前路由与列表中某个路由匹配，返回该路由的索引；否则，默认返回 0。
  int _getCurrentIndex(String currentLocation) {
    for (int i = 0; i < routes.length; i++) {
      if (currentLocation.startsWith(routes[i])) {
        return i; // 如果找到匹配的路由，返回其索引。
      }
    }
    return 0; // default index, 如果没有找到匹配的路由，默认返回索引 0。
  }

  @override
  Widget build(BuildContext context) {
    final location = context.location; // 获取当前的路由位置（即页面的路径）。
    final index = _getCurrentIndex(location); // 使用当前路由位置，确定其在路由列表中的索引。

    // 调用构建函数，传入当前上下文、路由列表和当前路由的索引，返回对应的widget。
    return builder(context, routes, index);
  }
}

mixin RouterListenerMixin<T extends StatefulWidget> on State<T> {
  RouterDelegate? delegate;

  void _listener() {
    setState(() {});
  }

  VoidCallback? disposer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    disposer?.call();
    final router = Router.of(context);
    delegate ??= router.routerDelegate as GetDelegate;

    delegate?.addListener(_listener);
    disposer = () => delegate?.removeListener(_listener);
  }

  @override
  void dispose() {
    super.dispose();
    disposer?.call();
  }
}

class RouterListenerInherited extends InheritedWidget {
  const RouterListenerInherited({
    super.key,
    required super.child,
  });

  static RouterListenerInherited? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<RouterListenerInherited>();
  }

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) {
    return true;
  }
}

class RouterListener extends StatefulWidget {
  const RouterListener({
    super.key,
    required this.builder,
  });
  final WidgetBuilder builder;

  @override
  State<RouterListener> createState() => RouteListenerState();
}

class RouteListenerState extends State<RouterListener> with RouterListenerMixin {
  @override
  Widget build(BuildContext context) {
    return RouterListenerInherited(child: Builder(builder: widget.builder));
  }
}

class BackButtonCallback extends StatefulWidget {
  const BackButtonCallback({super.key, required this.builder});
  final WidgetBuilder builder;

  @override
  State<BackButtonCallback> createState() => RouterListenerState();
}

class RouterListenerState extends State<BackButtonCallback> with RouterListenerMixin {
  late ChildBackButtonDispatcher backButtonDispatcher;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final router = Router.of(context);
    backButtonDispatcher = router.backButtonDispatcher!.createChildBackButtonDispatcher();
  }

  @override
  Widget build(BuildContext context) {
    backButtonDispatcher.takePriority();
    return widget.builder(context);
  }
}
