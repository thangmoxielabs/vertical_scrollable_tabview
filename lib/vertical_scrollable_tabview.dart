import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:rect_getter/rect_getter.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

/// Detect TabBar Status, isOnTap = is to check TabBar is on Tap or not, isOnTapIndex = is on Tap Index
/// 增廁 TabBar 的狀態，isOnTap 是用來判斷是否是被點擊的狀態，isOnTapIndex 是用來儲存 TapBar 的 Index 的。
class VerticalScrollableTabBarStatus {
  static bool isOnTap = false;
  static int isOnTapIndex = 0;

  static void setIndex(int index) {
    VerticalScrollableTabBarStatus.isOnTap = true;
    VerticalScrollableTabBarStatus.isOnTapIndex = index;
  }
}

/// VerticalScrollPosition = is ann Animation style from scroll_to_index plugin's preferPosition,
/// It's show the item position in listView.builder
/// 用來設定動畫狀態的（參考 scroll_to_index 的 preferPosition 屬性）
enum VerticalScrollPosition { begin, middle, end }

class VerticalScrollableTabView extends StatefulWidget {
  /// TabBar Controller to let widget listening TabBar changed
  /// TabBar Controller 用來讓 widget 監聽 TabBar 的 index 是否有更動
  final TabController _tabController;

  /// A callback that return an Object inside _listItemData and the index of ListView.Builder
  /// A callback 用來回傳一個 _listItemData 裡面的 Object 型態和 ListView.Builder 的 index
  final Widget? Function(BuildContext, int) _itemBuilder;

  /// VerticalScrollPosition = is ann Animation style from scroll_to_index,
  /// It's show the item position in listView.builder
  final VerticalScrollPosition _verticalScrollPosition;

  /// Required SliverAppBar, And TabBar must inside of SliverAppBar, and In the TabBar
  /// onTap: (index) => VerticalScrollableTabBarStatus.setIndex(index);
  final List<Widget> _slivers;

  final AutoScrollController _autoScrollController;

  final int tabCount;

  /// Copy Scrollbar
  final bool? _thumbVisibility;
  final bool? _trackVisibility;
  final double? _thickness;
  final Radius? _radius;
  final bool Function(ScrollNotification)? _notificationPredicate;
  final bool? _interactive;
  final ScrollbarOrientation? _scrollbarOrientation;

  /// Copy CustomScrollView parameters
  final Axis _scrollDirection;
  final bool _reverse;
  final bool? _primary;
  final ScrollPhysics? _physics;
  final ScrollBehavior? _scrollBehavior;
  final bool _shrinkWrap;
  final Key? _center;
  final double _anchor;
  final double? _cacheExtent;
  final int? _semanticChildCount;
  final DragStartBehavior _dragStartBehavior;
  final ScrollViewKeyboardDismissBehavior _keyboardDismissBehavior;
  final String? _restorationId;
  final Clip _clipBehavior;

  final bool scrollOnUserInteraction;

  const VerticalScrollableTabView({
    Key? key,
    this.scrollOnUserInteraction = true,

    /// Custom parameters
    required AutoScrollController autoScrollController,
    required TabController tabController,
    required Widget? Function(BuildContext, int) itemBuilder,
    VerticalScrollPosition verticalScrollPosition =
        VerticalScrollPosition.begin,

    /// Copy Scrollbar
    bool? scrollbarThumbVisibility,
    bool? scrollbarTrackVisibility,
    double? scrollbarThickness,
    Radius? scrollbarRadius,
    bool Function(ScrollNotification)? scrollbarNotificationPredicate,
    bool? scrollInteractive,
    ScrollbarOrientation? scrollbarOrientation,

    /// Copy CustomScrollView parameters
    Axis scrollDirection = Axis.vertical,
    bool reverse = false,
    bool? primary,
    ScrollPhysics? physics,
    ScrollBehavior? scrollBehavior,
    bool shrinkWrap = false,
    Key? center,
    double anchor = 0.0,
    double? cacheExtent,
    required List<Widget> slivers,
    int? semanticChildCount,
    DragStartBehavior dragStartBehavior = DragStartBehavior.start,
    ScrollViewKeyboardDismissBehavior keyboardDismissBehavior =
        ScrollViewKeyboardDismissBehavior.manual,
    String? restorationId,
    Clip clipBehavior = Clip.hardEdge,
    required this.tabCount,
  })  : _tabController = tabController,
        _itemBuilder = itemBuilder,
        _verticalScrollPosition = verticalScrollPosition,
        _autoScrollController = autoScrollController,

        /// Scrollbar
        _thumbVisibility = scrollbarThumbVisibility,
        _trackVisibility = scrollbarTrackVisibility,
        _thickness = scrollbarThickness,
        _radius = scrollbarRadius,
        _notificationPredicate = scrollbarNotificationPredicate,
        _interactive = scrollInteractive,
        _scrollbarOrientation = scrollbarOrientation,

        /// CustomScrollView
        _scrollDirection = scrollDirection,
        _reverse = reverse,
        _primary = primary,
        _physics = physics,
        _scrollBehavior = scrollBehavior,
        _shrinkWrap = shrinkWrap,
        _center = center,
        _anchor = anchor,
        _cacheExtent = cacheExtent,
        _slivers = slivers,
        _semanticChildCount = semanticChildCount,
        _dragStartBehavior = dragStartBehavior,
        _keyboardDismissBehavior = keyboardDismissBehavior,
        _restorationId = restorationId,
        _clipBehavior = clipBehavior,
        super(key: key);

  @override
  State<VerticalScrollableTabView> createState() =>
      _VerticalScrollableTabViewState();
}

class _VerticalScrollableTabViewState extends State<VerticalScrollableTabView>
    with SingleTickerProviderStateMixin {
  /// Instantiate RectGetter（套件提供的方法）
  final listViewKey = RectGetter.createGlobalKey();

  /// To save the item's Rect
  /// 用來儲存 items 的 Rect 的 Map
  Map<int, dynamic> itemsKeys = {};

  @override
  void initState() {
    widget._tabController.addListener(_handleTabControllerTick);
    super.initState();
  }

  @override
  void dispose() {
    widget._tabController.removeListener(_handleTabControllerTick);
    // We don't own the _tabController, so it's not disposed here.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RectGetter(
      key: listViewKey,
      // NotificationListener 是一個由下往上傳遞通知，true 阻止通知、false 傳遞通知，確保指監聽滾動的通知
      // ScrollNotification => https://www.jianshu.com/p/d80545454944
      child: (widget.scrollOnUserInteraction
          ? NotificationListener<UserScrollNotification>.new
          : NotificationListener<ScrollNotification>.new)(
        onNotification: onScrollNotification,
        child: Scrollbar(
          controller: widget._autoScrollController,
          thumbVisibility: widget._thumbVisibility,
          trackVisibility: widget._trackVisibility,
          thickness: widget._thickness,
          radius: widget._radius,
          notificationPredicate: widget._notificationPredicate,
          interactive: widget._interactive,
          scrollbarOrientation: widget._scrollbarOrientation,
          child: CustomScrollView(
            scrollDirection: widget._scrollDirection,
            reverse: widget._reverse,
            controller: widget._autoScrollController,
            primary: widget._primary,
            physics: widget._physics,
            scrollBehavior: widget._scrollBehavior,
            shrinkWrap: widget._shrinkWrap,
            center: widget._center,
            anchor: widget._anchor,
            cacheExtent: widget._cacheExtent,
            slivers: [...widget._slivers, buildVerticalSliverList()],
            semanticChildCount: widget._semanticChildCount,
            dragStartBehavior: widget._dragStartBehavior,
            keyboardDismissBehavior: widget._keyboardDismissBehavior,
            restorationId: widget._restorationId,
            clipBehavior: widget._clipBehavior,
          ),
        ),
      ),
    );
  }

  SliverList buildVerticalSliverList() {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          // 建立 itemKeys 的 Key
          itemsKeys.putIfAbsent(index, () => RectGetter.createGlobalKey());
          return buildItem(context, index);
        },
      ),
    );
  }

  Widget? buildItem(BuildContext context, int index) {
    final child = widget._itemBuilder(context, index);
    if (child == null) return null;
    return RectGetter(
      /// when announce GlobalKey，we can use RectGetter.getRectFromKey(key) to get Rect
      /// 宣告 GlobalKey，之後可以 RectGetter.getRectFromKey(key) 的方式獲得 Rect
      key: itemsKeys[index],
      child: AutoScrollTag(
        key: ValueKey(index),
        index: index,
        controller: widget._autoScrollController,
        child: child,
      ),
    );
  }

  /// Animation Function for tabBarListener
  /// This need to put inside TabBar onTap, but in this case we put inside tabBarListener
  void animateAndScrollTo(int index) async {
    widget._tabController.animateTo(index % widget.tabCount);
    switch (widget._verticalScrollPosition) {
      case VerticalScrollPosition.begin:
        widget._autoScrollController
            .scrollToIndex(index, preferPosition: AutoScrollPosition.begin);
        break;
      case VerticalScrollPosition.middle:
        widget._autoScrollController
            .scrollToIndex(index, preferPosition: AutoScrollPosition.middle);
        break;
      case VerticalScrollPosition.end:
        widget._autoScrollController
            .scrollToIndex(index, preferPosition: AutoScrollPosition.end);
        break;
    }
  }

  /// onScrollNotification of NotificationListener
  /// true表示消費掉當前通知不再向上一级NotificationListener傳遞通知，false則會再向上一级NotificationListener傳遞通知；
  bool onScrollNotification(ScrollNotification notification) {
    List<int> visibleItems = getVisibleItemsIndex();
    if (visibleItems.isEmpty) return false;
    widget._tabController.animateTo(visibleItems[0] % widget.tabCount);
    return false;
  }

  /// getVisibleItemsIndex on Screen
  /// 取得現在畫面上可以看得到的 Items Index
  List<int> getVisibleItemsIndex() {
    // get ListView Rect
    Rect? rect = RectGetter.getRectFromKey(listViewKey);
    List<int> items = [];
    if (rect == null) return items;

    bool isHorizontalScroll = widget._scrollDirection == Axis.horizontal;
    itemsKeys.forEach((index, key) {
      Rect? itemRect = RectGetter.getRectFromKey(key);
      if (itemRect == null) return;
      // y 軸座越大，代表越下面
      // 如果 item 上方的座標 比 listView 的下方的座標 的位置的大 代表不在畫面中。
      // bottom meaning => The offset of the bottom edge of this widget from the y axis.
      // top meaning => The offset of the top edge of this widget from the y axis.
      //Change offset based on AxisOrientation [horizontal] [vertical]
      switch (isHorizontalScroll) {
        case true:
          if (itemRect.left > rect.right) return;
          if (itemRect.right < rect.left) return;
          break;
        case false:
          if (itemRect.top > rect.bottom) return;
          // 如果 item 下方的座標 比 listView 的上方的座標 的位置的小 代表不在畫面中。
          if (itemRect.bottom <
              rect.top +
                  MediaQuery.of(context).viewPadding.top +
                  kToolbarHeight +
                  56) return;
          break;
      }

      items.add(index);
    });
    return items;
  }

  void _handleTabControllerTick() {
    if (VerticalScrollableTabBarStatus.isOnTap) {
      VerticalScrollableTabBarStatus.isOnTap = false;
      animateAndScrollTo(VerticalScrollableTabBarStatus.isOnTapIndex);
    }
  }
}
