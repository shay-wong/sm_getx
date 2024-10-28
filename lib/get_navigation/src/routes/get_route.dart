// ignore_for_file: overridden_fields

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../get_instance/src/bindings_interface.dart';
import '../../../get_state_manager/src/simple/get_state.dart';
import '../../get_navigation.dart';

class GetPage<T> extends Page<T> {
  final GetPageBuilder page;
  final bool? popGesture;
  final Map<String, String>? parameters;
  final String? title;
  final Transition? transition;
  final Curve curve;
  final bool? participatesInRootNavigator;
  final Alignment? alignment;
  final bool maintainState;
  final bool opaque;

  /// 手势的宽度, [limitedSwipe] 为 true 时生效, 默认为 [MediaQueryData.padding] 的 [left] 或 [right]
  final double Function(BuildContext context)? gestureWidth;
  final BindingsInterface? binding;
  final List<BindingsInterface> bindings;
  final List<Bind> binds;
  final CustomTransition? customTransition;
  final Duration? transitionDuration;
  final Duration? reverseTransitionDuration;
  final bool fullscreenDialog;
  final bool preventDuplicates;
  final Completer<T?>? completer;
  // @override
  // final LocalKey? key;

  // @override
  // RouteSettings get settings => this;

  @override
  final Object? arguments;

  @override
  final String name;

  final bool inheritParentPath;

  final List<GetPage> children;
  final List<GetMiddleware> middlewares;
  final PathDecoded path;
  final GetPage? unknownRoute;
  final bool showCupertinoParallax;

  /// 如果当要添加的新路由, 是在路由栈中已存在的重复的路由, 那么该情况下的处理方式
  final PreventDuplicateHandlingMode preventDuplicateHandlingMode;

  /// 是否限制滑动手势的触发距离, 默认为 false 全屏手势
  final bool? limitedSwipe;

  /// 滑动手势的初始偏移, [limitedSwipe] 为 true 时生效, 默认为 0
  final double? initialOffset;
  static void _defaultPopInvokedHandler(bool didPop, Object? result) {}

  GetPage({
    required this.name,
    required this.page,
    this.title,
    this.participatesInRootNavigator,
    this.gestureWidth,
    // RouteSettings settings,
    this.maintainState = true,
    this.curve = Curves.linear,
    this.alignment,
    this.parameters,
    this.opaque = true,
    this.transitionDuration,
    this.reverseTransitionDuration,
    this.popGesture,
    this.binding,
    this.bindings = const [],
    this.binds = const [],
    this.transition,
    this.customTransition,
    this.fullscreenDialog = false,
    this.children = const <GetPage>[],
    this.middlewares = const [],
    this.unknownRoute,
    this.arguments,
    this.showCupertinoParallax = true,
    this.preventDuplicates = true,
    this.preventDuplicateHandlingMode =
        PreventDuplicateHandlingMode.reorderRoutes,
    this.completer,
    this.inheritParentPath = true,
    this.limitedSwipe,
    this.initialOffset,
    LocalKey? key,
    super.canPop,
    super.onPopInvoked = _defaultPopInvokedHandler,
    super.restorationId,
  })  : path = _nameToRegex(name),
        assert(name.startsWith('/'),
            'It is necessary to start route name [$name] with a slash: /$name'),
        super(
          key: key ?? ValueKey(name),
          name: name,
          // arguments: Get.arguments,
        );
  // settings = RouteSettings(name: name, arguments: Get.arguments);

  GetPage<T> copyWith({
    LocalKey? key,
    String? name,
    GetPageBuilder? page,
    bool? popGesture,
    Map<String, String>? parameters,
    String? title,
    Transition? transition,
    Curve? curve,
    Alignment? alignment,
    bool? maintainState,
    bool? opaque,
    List<BindingsInterface>? bindings,
    BindingsInterface? binding,
    List<Bind>? binds,
    CustomTransition? customTransition,
    Duration? transitionDuration,
    Duration? reverseTransitionDuration,
    bool? fullscreenDialog,
    RouteSettings? settings,
    List<GetPage<T>>? children,
    GetPage? unknownRoute,
    List<GetMiddleware>? middlewares,
    bool? preventDuplicates,
    final double Function(BuildContext context)? gestureWidth,
    bool? participatesInRootNavigator,
    Object? arguments,
    bool? showCupertinoParallax,
    Completer<T?>? completer,
    bool? inheritParentPath,
    bool? canPop,
    PopInvokedWithResultCallback<T>? onPopInvoked,
    String? restorationId,
  }) {
    return GetPage(
      key: key ?? this.key,
      participatesInRootNavigator:
          participatesInRootNavigator ?? this.participatesInRootNavigator,
      preventDuplicates: preventDuplicates ?? this.preventDuplicates,
      name: name ?? this.name,
      page: page ?? this.page,
      popGesture: popGesture ?? this.popGesture,
      parameters: parameters ?? this.parameters,
      title: title ?? this.title,
      transition: transition ?? this.transition,
      curve: curve ?? this.curve,
      alignment: alignment ?? this.alignment,
      maintainState: maintainState ?? this.maintainState,
      opaque: opaque ?? this.opaque,
      bindings: bindings ?? this.bindings,
      binds: binds ?? this.binds,
      binding: binding ?? this.binding,
      customTransition: customTransition ?? this.customTransition,
      transitionDuration: transitionDuration ?? this.transitionDuration,
      reverseTransitionDuration:
          reverseTransitionDuration ?? this.reverseTransitionDuration,
      fullscreenDialog: fullscreenDialog ?? this.fullscreenDialog,
      children: children ?? this.children,
      unknownRoute: unknownRoute ?? this.unknownRoute,
      middlewares: middlewares ?? this.middlewares,
      gestureWidth: gestureWidth ?? this.gestureWidth,
      arguments: arguments ?? this.arguments,
      showCupertinoParallax:
          showCupertinoParallax ?? this.showCupertinoParallax,
      completer: completer ?? this.completer,
      inheritParentPath: inheritParentPath ?? this.inheritParentPath,
      canPop: canPop ?? this.canPop,
      onPopInvoked: onPopInvoked ?? this.onPopInvoked,
      restorationId: restorationId ?? restorationId,
    );
  }

  @override
  Route<T> createRoute(BuildContext context) {
    // return GetPageRoute<T>(settings: this, page: page);
    final page = PageRedirect(
      route: this,
      settings: this,
      unknownRoute: unknownRoute,
    ).getPageToRoute<T>(this, unknownRoute, context);

    return page;
  }

  /// 用于将 URL 路径模式转换为正则表达式，同时提取路径参数。
  /// 这种功能在路由管理中非常有用，允许开发者定义具有动态部分的 URL 路径，并在运行时匹配和提取这些部分。
  /// 这个函数用于路由管理系统中，允许开发者定义动态路由，其中某些部分可以是可变的。
  /// 通过将路径模式转换为正则表达式，并提取路径参数，路由管理器可以在应用接收到特定 URL 请求时，识别并匹配对应的路由规则，然后据此渲染相应的页面或执行其他操作。
  /// [path] : 一个字符串，代表要转换的 URL 路径模式。
  /// 返回一个 [PathDecoded] 对象，其中包含用于匹配路径的正则表达式和提取的路径参数名称列表。
  ///
  ///
  /// The function defined below converts each word in a string to simplified
  /// 'pig latin' using [replaceAllMapped]:
  /// ```dart
  /// String pigLatin(String words) => words.replaceAllMapped(
  ///     RegExp(r'\b(\w*?)([aeiou]\w*)', caseSensitive: false),
  ///     (Match m) => "${m[2]}${m[1]}${m[1]!.isEmpty ? 'way' : 'ay'}");
  ///
  /// final result = _nameToRegex('/home/products/:productId');
  /// print(keys); // ["productId"]
  /// print(stringPath); // '/home/products/(?:([\w%+-._~!$&'()*,;=:@]+))/?'
  /// ```
  static PathDecoded _nameToRegex(String path) {
    // 初始化 keys 数组：keys 用于存储从路径模式中提取的参数名称。
    var keys = <String?>[];

    // 定义 recursiveReplace 函数：这个内部函数被设计为 replaceAllMapped 方法的回调，用于处理每一个正则表达式匹配的结果。
    String recursiveReplace(Match pattern) {
      var buffer = StringBuffer('(?:');

      // 如果模式中包含一个点号（.），表示这部分是可选的，它会在生成的正则表达式中添加一个非捕获组 (?:...)。
      if (pattern[1] != null) buffer.write('.');
      // 捕获组 ([\\w%+-._~!\$&'()*,;=:@]+)) 用于匹配 URL 中有效的字符。
      buffer.write('([\\w%+-._~!\$&\'()*,;=:@]+))');
      // 如果路径模式的这部分是可选的（由 ? 表示），则在正则表达式中为这个捕获组添加一个问号，表示这个组是可选的。
      if (pattern[3] != null) buffer.write('?');

      // 将每个匹配到的参数名称添加到 keys 数组中。
      keys.add(pattern[2]);
      // 如果所有条件成立, 最终的 buffer 为 (?:.([\w%+-._~!\$&'()*,;=:@]+))?
      return "$buffer";
    }

    // 路径模式的预处理：
    // 给 path 字符串的末尾添加 /?，以匹配以 / 结尾的路径，
    // 然后使用 replaceAllMapped 方法和定义好的 recursiveReplace 回调函数来将路径模式中的参数部分（如 :param）转换为正则表达式的形式。
    // 这个正则表达式分为三个主要部分，每个部分对应一个特定的匹配目标：
    // * pattern[1]. (\.)?：这个部分匹配路径中的点（.）字符。点字符是可选的，意味着它可能出现也可能不出现。这通常用于表明参数前的特定前缀或格式要求。例如，在某些路由设计中，可能会使用点来特别标记参数。
    // * pattern[2]. (\w+)：这个部分匹配由一个或多个字母数字字符（包括下划线）组成的字符串。这代表了参数的名称。\w 是一个正则表达式的特殊字符类，匹配任何字母数字字符（等价于 [a-zA-Z0-9_]）。加号（+）表示匹配一个或多个前面的字符。
    // * pattern[3]. (\?)?：这个部分匹配问号（?）字符。问号是可选的，表示紧随其前的元素（在这里是参数名称）也是可选的。在路由路径中使用问号后缀通常意味着该参数不是必需的，即路径可以包含该参数也可以不包含而仍然被认为是有效的。
    // 这个正则表达式用于匹配形如 :paramName 或 .:paramName 或 :paramName? 的路由参数声明。
    // 在 recursiveReplace 函数中，通过这个正则表达式识别出的组件（.、参数名、?）被用于构建新的正则表达式，这个新的正则表达式将用于实际的路径匹配。
    // 同时，参数名称（匹配的第二部分）被收集到 keys 数组中，以便后续使用。
    // 最后，用 replaceAll 方法替换所有双斜杠 // 为单斜杠 /，以避免生成无效的正则表达式。
    var stringPath = '$path/?'
        .replaceAllMapped(RegExp(r'(\.)?:(\w+)(\?)?'), recursiveReplace)
        .replaceAll('//', '/');

    // 生成并返回 PathDecoded 对象：使用处理后的 stringPath 创建一个 RegExp 对象，并将其与提取的 keys 数组一起封装在一个 PathDecoded 对象中返回。PathDecoded 是一个自定义类，它包含了生成的正则表达式和路径参数名称列表。
    return PathDecoded(RegExp('^$stringPath\$'), keys);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GetPage<T> && other.key == key;
  }

  @override
  String toString() =>
      '${objectRuntimeType(this, 'Page')}("$name", $key, $arguments)';

  @override
  int get hashCode {
    return key.hashCode;
  }
}

/// 包含用于匹配路径的正则表达式 [regex] 和提取的路径参数名称列表 [keys] 的对象。
@immutable
class PathDecoded {
  /// 用于匹配路径的正则表达式
  final RegExp regex;

  /// 提取的路径参数名称列表
  final List<String?> keys;
  const PathDecoded(this.regex, this.keys);

  @override
  int get hashCode => regex.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PathDecoded &&
        other.regex == regex; // && listEquals(other.keys, keys);
  }
}
