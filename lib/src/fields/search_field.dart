import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:macos_ui/src/library.dart';

const BorderRadius _kBorderRadius = BorderRadius.all(Radius.circular(7.0));
const double _kResultHeight = 20.0;

/// A macOS-style search field.
class MacosSearchField<T> extends StatefulWidget {
  /// Creates a macOS-style search field.
  ///
  /// To provide a prefilled text entry, pass in a [TextEditingController] with
  /// an initial value to the [controller] parameter.
  ///
  /// To provide a hint placeholder text that appears when the text entry is
  /// empty, pass a [String] to the [placeholder] parameter.
  ///
  /// Based on a [MacosTextField] widget.
  ///
  /// When focused or tapped, it opens an overlay showing a [results] list
  /// of [SearchResultItem]s to choose from.
  ///
  /// If searching yields no results, the [emptyWidget] is shown instead (set
  /// by default to [SizedBox.shrink]).
  ///
  /// Set what happens when selecting a suggestion item via the
  /// [onResultSelected] property.
  ///
  /// You can also set a callback action individually for each
  /// [SearchResultItem] via the [onSelected] property.
  const MacosSearchField({
    super.key,
    this.results,
    this.onResultSelected,
    this.maxResultsToShow = 5,
    this.resultHeight = _kResultHeight,
    this.emptyWidget = const SizedBox.shrink(),
    this.controller,
    this.focusNode,
    this.decoration = kDefaultRoundedBorderDecoration,
    this.focusedDecoration = kDefaultFocusedBorderDecoration,
    this.padding = const EdgeInsets.all(4.0),
    this.placeholder = "Search",
    this.placeholderStyle = const TextStyle(
      fontWeight: FontWeight.w400,
      color: CupertinoColors.placeholderText,
    ),
    this.style,
    this.textAlign = TextAlign.start,
    this.autocorrect = true,
    this.autofocus = false,
    this.maxLines,
    this.minLines,
    this.expands = false,
    this.maxLength,
    this.maxLengthEnforcement,
    this.onChanged,
    this.onSubmitted,
    this.inputFormatters,
    this.enabled = true,
    this.onTap,
  }) : assert(maxResultsToShow > 0),
       assert(resultHeight > 0);

  /// List of results for the searchfield.
  ///
  /// Each suggestion should have a unique searchKey.
  ///
  /// ```dart
  /// ['ABC', 'DEF', 'GHI', 'JKL']
  ///   .map((e) => SearchResultItem(e, child: Text(e)))
  ///   .toList(),
  /// ```
  final List<SearchResultItem>? results;

  /// The action to perform when any suggestion is selected.
  final Function(SearchResultItem)? onResultSelected;

  /// Specifies the number of results that will be displayed.
  ///
  /// Defaults to `5`.
  final int maxResultsToShow;

  /// Specifies the height of each suggestion item in the list.
  ///
  /// When not specified, the default value is `20.0`.
  final double resultHeight;

  /// Widget to show when the search returns no results.
  ///
  /// Defaults to [SizedBox.shrink].
  final Widget emptyWidget;

  /// Specifies the `TextEditingController` for [MacosSearchField].
  final TextEditingController? controller;

  /// {@macro flutter.widgets.Focus.focusNode}
  final FocusNode? focusNode;

  /// Controls the [BoxDecoration] of the box behind the text input.
  ///
  /// Defaults to having a rounded rectangle grey border and can be null to have
  /// no box decoration.
  final BoxDecoration? decoration;

  /// Controls the [BoxDecoration] of the box behind the text input when focused.
  /// This decoration is drawn above [decoration].
  ///
  /// Defaults to having a rounded rectangle blue border and can be null to have
  /// no box decoration.
  final BoxDecoration? focusedDecoration;

  /// Padding around the text entry area.
  ///
  /// Defaults to a padding of 6 pixels on all sides and can be null.
  final EdgeInsets padding;

  /// A lighter colored placeholder hint that appears on the first line of the
  /// text field when the text entry is empty.
  ///
  /// Defaults to having no placeholder text.
  ///
  /// The text style of the placeholder text matches that of the text field's
  /// main text entry except a lighter font weight and a grey font color.
  final String? placeholder;

  /// The style to use for the placeholder text.
  ///
  /// The [placeholderStyle] is merged with the [style] [TextStyle] when applied
  /// to the [placeholder] text. To avoid merging with [style], specify
  /// [TextStyle.inherit] as false.
  ///
  /// Defaults to the [style] property with w300 font weight and grey color.
  ///
  /// If specifically set to null, placeholder's style will be the same as [style].
  final TextStyle? placeholderStyle;

  /// The style to use for the text being edited.
  ///
  /// Also serves as a base for the [placeholder] text's style.
  ///
  /// Defaults to the standard font style from [MacosTheme] if null.
  final TextStyle? style;

  /// {@macro flutter.widgets.editableText.textAlign}
  final TextAlign textAlign;

  /// {@macro flutter.widgets.editableText.autofocus}
  final bool autofocus;

  /// {@macro flutter.widgets.editableText.autocorrect}
  final bool autocorrect;

  /// {@macro flutter.widgets.editableText.maxLines}
  final int? maxLines;

  /// {@macro flutter.widgets.editableText.minLines}
  final int? minLines;

  /// {@macro flutter.widgets.editableText.expands}
  final bool expands;

  /// The maximum number of characters (Unicode scalar values) to allow in the
  /// text field.
  ///
  /// After [maxLength] characters have been input, additional input
  /// is ignored, unless [maxLengthEnforcement] is set to
  /// [MaxLengthEnforcement.none].
  ///
  /// The TextField enforces the length with a
  /// [LengthLimitingTextInputFormatter], which is evaluated after the supplied
  /// [inputFormatters], if any.
  ///
  /// This value must be either null or greater than zero. If set to null
  /// (the default), there is no limit to the number of characters allowed.
  ///
  /// Whitespace characters (e.g. newline, space, tab) are included in the
  /// character count.
  ///
  /// {@macro flutter.services.lengthLimitingTextInputFormatter.maxLength}
  final int? maxLength;

  /// Determines how the [maxLength] limit should be enforced.
  ///
  /// If [MaxLengthEnforcement.none] is set, additional input beyond [maxLength]
  /// will not be enforced by the limit.
  ///
  /// {@macro flutter.services.textFormatter.effectiveMaxLengthEnforcement}
  ///
  /// {@macro flutter.services.textFormatter.maxLengthEnforcement}
  final MaxLengthEnforcement? maxLengthEnforcement;

  /// Use this to get the current search query of the [MacosSearchField].
  ///
  /// {@macro flutter.widgets.editableText.onChanged}
  final ValueChanged<String>? onChanged;

  /// Called when Enter submits a query without an active suggestion.
  /// Selecting a suggestion uses [onResultSelected] instead.
  final ValueChanged<String>? onSubmitted;

  /// {@macro flutter.widgets.editableText.inputFormatters}
  final List<TextInputFormatter>? inputFormatters;

  /// Disables the text field when false.
  ///
  /// Text fields in disabled states have a light grey background and don't
  /// respond to touch events including the [prefix], [suffix] and the clear
  /// button.
  final bool? enabled;

  /// {@macro flutter.material.textfield.onTap}
  final GestureTapCallback? onTap;

  @override
  State<MacosSearchField<T>> createState() => _MacosSearchFieldState();
}

class _MacosSearchFieldState<T> extends State<MacosSearchField<T>> {
  late TextEditingController _controller;
  late FocusNode _focus;
  final _portal = OverlayPortalController();
  final _link = LayerLink();
  final _scroll = ScrollController();
  int _selected = -1;
  String _lastText = '';
  bool _open = false;
  bool get _enabled => widget.enabled != false;

  List<SearchResultItem> get _results {
    final query = _controller.text.toLowerCase();
    return widget.results
            ?.where((item) => item.searchKey.toLowerCase().contains(query))
            .toList() ??
        [];
  }

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focus = widget.focusNode ?? FocusNode();
    _lastText = _controller.text;
    _controller.addListener(_queryChanged);
    _focus.addListener(_focusChanged);
  }

  @override
  void didUpdateWidget(MacosSearchField<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      final value = _controller.value;
      _controller.removeListener(_queryChanged);
      if (oldWidget.controller == null) _controller.dispose();
      _controller = widget.controller ?? TextEditingController.fromValue(value);
      _lastText = _controller.text;
      _controller.addListener(_queryChanged);
    }
    if (oldWidget.focusNode != widget.focusNode) {
      _focus.removeListener(_focusChanged);
      if (oldWidget.focusNode == null) _focus.dispose();
      _focus = widget.focusNode ?? FocusNode();
      _focus.addListener(_focusChanged);
      _dismiss();
    }
    _selected = -1;
    if (!_enabled) _dismiss();
  }

  void _queryChanged() {
    if (!mounted || _lastText == _controller.text) return;
    _lastText = _controller.text;
    setState(() => _selected = -1);
    if (_focus.hasFocus && _enabled) _show();
  }

  void _focusChanged() {
    if (_focus.hasFocus && _enabled) {
      _show();
    } else {
      _dismiss();
    }
  }

  void _show() {
    if (!_enabled) return;
    setState(() => _open = true);
    _portal.show();
  }

  void _dismiss() {
    _open = false;
    _selected = -1;
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_open) _portal.hide();
      });
    } else {
      _portal.hide();
    }
  }

  void _choose(SearchResultItem item) {
    _controller.value = TextEditingValue(
      text: item.searchKey,
      selection: TextSelection.collapsed(offset: item.searchKey.length),
    );
    _dismiss();
    item.onSelected?.call();
    widget.onResultSelected?.call(item);
  }

  KeyEventResult _key(FocusNode node, KeyEvent event) {
    if (!_enabled ||
        event is KeyUpEvent ||
        HardwareKeyboard.instance.isMetaPressed ||
        HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isAltPressed ||
        HardwareKeyboard.instance.isShiftPressed ||
        !_controller.value.composing.isCollapsed) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.escape && _open) {
      setState(_dismiss);
      return KeyEventResult.handled;
    }
    final results = _results;
    if (key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.arrowUp) {
      if (results.isEmpty) return KeyEventResult.ignored;
      _show();
      setState(() {
        _selected = key == LogicalKeyboardKey.arrowDown
            ? (_selected + 1) % results.length
            : (_selected <= 0 ? results.length - 1 : _selected - 1);
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_scroll.hasClients || _selected < 0) return;
        final extent = _rowHeight(context);
        final top = _selected * extent;
        final bottom = top + extent;
        final position = _scroll.position;
        if (top < position.pixels ||
            bottom > position.pixels + position.viewportDimension) {
          _scroll.jumpTo(
            (top < position.pixels ? top : bottom - position.viewportDimension)
                .clamp(0.0, position.maxScrollExtent),
          );
        }
      });
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter &&
        _open &&
        _selected >= 0 &&
        _selected < results.length) {
      setState(() => _choose(results[_selected]));
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  double _rowHeight(BuildContext context) => math.max(
    widget.resultHeight,
    MediaQuery.textScalerOf(context).scale(13) + 12,
  );

  Widget _overlay(BuildContext context) {
    if (!_open || !_enabled || widget.results == null) {
      return const SizedBox.shrink();
    }
    final box = this.context.findRenderObject() as RenderBox;
    final screen = MediaQuery.sizeOf(context);
    final origin = box.localToGlobal(Offset.zero);
    final below = math.max(
      0.0,
      screen.height - origin.dy - box.size.height - 8,
    );
    final above = math.max(0.0, origin.dy - 8);
    final flip =
        below <
            _rowHeight(context) *
                math.min(widget.maxResultsToShow, _results.length) &&
        above > below;
    final chrome = MacosChromeData.of(context);
    final theme = MacosSearchFieldTheme.of(context);
    final results = _results;
    final rowHeight = _rowHeight(context);
    return Positioned(
      left: 0,
      top: 0,
      width: math.min(box.size.width, screen.width),
      child: CompositedTransformFollower(
        link: _link,
        showWhenUnlinked: false,
        targetAnchor: flip ? Alignment.topLeft : Alignment.bottomLeft,
        followerAnchor: flip ? Alignment.bottomLeft : Alignment.topLeft,
        child: TextFieldTapRegion(
          child: Container(
            constraints: BoxConstraints(maxHeight: flip ? above : below),
            decoration: BoxDecoration(
              color: theme.resultsBackgroundColor ?? chrome.canvas,
              borderRadius: _kBorderRadius,
              border: Border.all(color: chrome.separator),
            ),
            child: results.isEmpty
                ? widget.emptyWidget
                : SizedBox(
                    height:
                        rowHeight *
                        math.min(results.length, widget.maxResultsToShow),
                    child: ListView.builder(
                      controller: _scroll,
                      padding: EdgeInsets.zero,
                      itemExtent: rowHeight,
                      itemCount: results.length,
                      itemBuilder: (context, index) => _SearchResultItemButton(
                        selected: index == _selected,
                        resultHeight: rowHeight,
                        onPressed: () =>
                            setState(() => _choose(results[index])),
                        child:
                            results[index].child ??
                            Text(
                              results[index].searchKey,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.removeListener(_queryChanged);
    _focus.removeListener(_focusChanged);
    if (widget.controller == null) _controller.dispose();
    if (widget.focusNode == null) _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Focus(
    canRequestFocus: false,
    onKeyEvent: _key,
    child: OverlayPortal(
      controller: _portal,
      overlayChildBuilder: _overlay,
      child: CompositedTransformTarget(
        link: _link,
        child: MacosTextField(
          textInputAction: TextInputAction.search,
          keyboardType: TextInputType.text,
          placeholder: widget.placeholder,
          prefix: const MacosIcon(CupertinoIcons.search),
          clearButtonMode: OverlayVisibilityMode.editing,
          onTap: () {
            _show();
            widget.onTap?.call();
          },
          controller: _controller,
          focusNode: _focus,
          style: widget.style,
          onChanged: widget.onChanged,
          onSubmitted: (value) {
            setState(_dismiss);
            widget.onSubmitted?.call(value);
          },
          decoration: widget.decoration,
          focusedDecoration: widget.focusedDecoration,
          padding: widget.padding,
          placeholderStyle: widget.placeholderStyle,
          textAlign: widget.textAlign,
          autocorrect: widget.autocorrect,
          autofocus: widget.autofocus,
          maxLines: widget.maxLines,
          minLines: widget.minLines,
          expands: widget.expands,
          maxLength: widget.maxLength,
          maxLengthEnforcement: widget.maxLengthEnforcement,
          inputFormatters: widget.inputFormatters,
          enabled: widget.enabled,
        ),
      ),
    ),
  );
}

/// An item to show in the search results of a search field.
class SearchResultItem {
  /// Creates a macOS-styled item to show in the search results of a search
  /// field.
  ///
  /// Can be further customized via its [child] property.
  const SearchResultItem(this.searchKey, {this.child, this.onSelected});

  /// The string to search for.
  final String searchKey;

  /// The widget to display in the search results overlay. If not specified, a
  /// [Text] widget with the default styling will appear instead.
  final Widget? child;

  /// The callback to call when this item is selected from the search results.
  final VoidCallback? onSelected;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is SearchResultItem &&
            runtimeType == other.runtimeType &&
            searchKey == other.searchKey;
  }

  @override
  int get hashCode => searchKey.hashCode;
}

/// A wrapper around the [SearchResultItem] to provide it with the
/// appropriate mouse and hover detection.
class _SearchResultItemButton extends StatefulWidget {
  // ignore: use_super_parameters
  const _SearchResultItemButton({
    Key? key,
    this.onPressed,
    required this.child,
    required this.resultHeight,
    this.selected = false,
  }) : super(key: key);

  final VoidCallback? onPressed;
  final Widget child;
  final double resultHeight;
  final bool selected;

  @override
  State<_SearchResultItemButton> createState() =>
      _SearchResultItemButtonState();
}

class _SearchResultItemButtonState extends State<_SearchResultItemButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final chrome = MacosChromeData.of(context);
    final highlighted = _isHovered || widget.selected;
    return MouseRegion(
      cursor: SystemMouseCursors.basic,
      onEnter: (_) {
        setState(() => _isHovered = true);
      },
      onExit: (_) {
        setState(() => _isHovered = false);
      },
      child: Semantics(
        button: true,
        selected: widget.selected,
        onTap: widget.onPressed,
        child: GestureDetector(
          onTap: widget.onPressed,
          child: Container(
            height: widget.resultHeight,
            decoration: BoxDecoration(
              color: highlighted
                  ? (MacosSearchFieldTheme.of(context).highlightColor ??
                        chrome.selection)
                  : Colors.transparent,
              borderRadius: _kBorderRadius,
            ),
            child: DefaultTextStyle(
              style: TextStyle(
                fontSize: 13.0,
                color: highlighted
                    ? (chrome.highContrast ? chrome.canvas : MacosColors.white)
                    : chrome.foreground,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
