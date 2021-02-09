// MIT License
//
// Copyright (c) 2020 Simon Lightfoot
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class Carousel extends StatefulWidget {
  const Carousel({
    Key key,
    @required this.itemCount,
    @required this.itemBuilder,
    this.controller,
  }) : super(key: key);

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final CarouselController controller;

  @override
  _CarouselState createState() => _CarouselState();
}

class _CarouselState extends State<Carousel> {
  CarouselController _controller;

  CarouselController get _effectiveController =>
      widget.controller ?? _controller;

  @override
  void initState() {
    super.initState();
    _controller = CarouselController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scrollable(
      axisDirection: AxisDirection.right,
      controller: _effectiveController,
      physics: CarouselScrollPhysics(
        _effectiveController,
        parent: AlwaysScrollableScrollPhysics(),
      ),
      viewportBuilder: (BuildContext context, ViewportOffset position) {
        return CarouselViewport(
          controller: _effectiveController,
          offset: position,
          children: [
            for (int index = 0; index < widget.itemCount; index++)
              KeyedSubtree.wrap(
                widget.itemBuilder(context, index),
                index,
              ),
          ],
        );
      },
    );
  }
}

class CarouselController extends ScrollController {
  CarouselController({
    double initialScrollOffset = 0.0,
    bool keepScrollOffset = true,
    String debugLabel,
  }) : super(
          initialScrollOffset: initialScrollOffset,
          keepScrollOffset: keepScrollOffset,
          debugLabel: debugLabel,
        );

  List<Offset> _centerPoints = [];

  List<Offset> get centerPoints => List.unmodifiable(_centerPoints);

  set centerPoints(List<Offset> value) {
    _centerPoints = List.from(value);
    notifyListeners();
  }

  double get centerIndex {
    double index = 0.0;
    if (_centerPoints.isEmpty || _centerPoints.length == 1) {
      return 0.0;
    }

    if (position.viewportDimension == null) {
      return 0.0;
    }

    double dx = position.pixels;
    final cw = position.viewportDimension / 2;
    final centerPoints = this.centerPoints;

    for (int i = 0; i < centerPoints.length; i++) {
      final cx = centerPoints[i].dx - cw;
      final cxPrev = i > 0 ? centerPoints[i - 1].dx - cw : cx;
      final cxNext =
          i + 1 >= centerPoints.length ? cx : centerPoints[i + 1].dx - cw;

      if (cx - dx >= 0) {
        double positionDiff = (dx - cx).abs();
        double pointsDiff = 0.0;

        if ((cxPrev - dx).abs() < (cx - dx).abs()) {
          pointsDiff = cxPrev - cx;
        } else {
          pointsDiff = cx - cxNext;
          if (i + 1 == centerPoints.length) {
            pointsDiff = cxPrev - cx;
          }
        }

        index = i.toDouble();
        if (pointsDiff.abs() < 0.001) {
          break;
        }
        // fractional part of index
        index += positionDiff / pointsDiff;
        break;
      } else if (i + 1 == centerPoints.length) {
        index = i.toDouble();
      }
    }
    return max(index, 0.0);
  }

  void animateToCenterIndex(
    int index, {
    @required Duration duration,
    @required Curve curve,
  }) {
    final cw = position.viewportDimension / 2;
    final cx = centerPoints[index].dx - cw;
    if (position.pixels == cx) {
      return;
    }
    animateTo(cx, duration: duration, curve: curve);
  }
}

class CarouselScrollPhysics extends ScrollPhysics {
  const CarouselScrollPhysics(
    this.controller, {
    ScrollPhysics parent,
  }) : super(parent: parent);

  final CarouselController controller;

  @override
  CarouselScrollPhysics applyTo(ScrollPhysics ancestor) {
    return CarouselScrollPhysics(controller, parent: buildParent(ancestor));
  }

  @override
  Simulation createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    // If we're out of range and not headed back in range, defer to the parent
    // ballistics, which should put us back in range at a page boundary.
    if ((velocity <= 0.0 && position.pixels <= position.minScrollExtent) ||
        (velocity >= 0.0 && position.pixels >= position.maxScrollExtent))
      return super.createBallisticSimulation(position, velocity);

    double target = position.pixels;

    final dx = ClampingScrollSimulation(
      position: position.pixels,
      velocity: velocity,
      tolerance: tolerance,
    ).x(1.0);
    final cw = position.viewportDimension / 2;
    final centerPoints = controller.centerPoints;
    for (int i = 0; i < centerPoints.length; i++) {
      // target scroll position corresponds to the viewport start thus
      // we offset center point by minus half of the viewport width
      final cx = centerPoints[i].dx - cw;
      if (cx - dx >= 0) {
        target = cx;
        // we need to check if previous item is closer to the target scoll position
        // and if so scroll to that
        if (i > 0) {
          final cxPrev = centerPoints[i - 1].dx - cw;
          if ((cxPrev - dx).abs() < (cx - dx).abs()) {
            target = cxPrev;
            break;
          }
        }
        break;
      } else if (i + 1 == centerPoints.length) {
        // target scroll position is outside of carousel, use last item as snap target
        target = cx;
      }
    }

    if (target != position.pixels) {
      return ScrollSpringSimulation(
        spring,
        position.pixels,
        target,
        velocity,
        tolerance: tolerance,
      );
    }

    return null;
  }

  @override
  bool get allowImplicitScrolling => false;
}

class CarouselViewport extends MultiChildRenderObjectWidget {
  CarouselViewport({
    Key key,
    @required this.controller,
    @required this.offset,
    List<Widget> children,
  }) : super(
          key: key,
          children: children,
        );

  final CarouselController controller;
  final ViewportOffset offset;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderCarouselViewport(controller: controller, offset: offset);
  }

  @override
  void updateRenderObject(
      BuildContext context, RenderCarouselViewport renderObject) {
    renderObject
      ..controller = controller
      ..offset = offset;
  }
}

class RenderCarouselViewport extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _CarouselParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _CarouselParentData> {
  RenderCarouselViewport({
    @required CarouselController controller,
    @required ViewportOffset offset,
  })  : _controller = controller,
        _offset = offset;

  CarouselController get controller => _controller;
  CarouselController _controller;

  set controller(CarouselController value) {
    assert(value != null);
    if (value == _controller) return;
    _controller = value;
    markNeedsLayout();
  }

  ViewportOffset get offset => _offset;
  ViewportOffset _offset;

  set offset(ViewportOffset value) {
    assert(value != null);
    if (value == _offset) return;
    if (attached) _offset.removeListener(markNeedsLayout);
    _offset = value;
    if (attached) _offset.addListener(markNeedsLayout);
    markNeedsLayout();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _offset.addListener(markNeedsLayout);
  }

  @override
  void detach() {
    _offset.removeListener(markNeedsLayout);
    super.detach();
  }

  @override
  bool get needsCompositing => true;

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _CarouselParentData) {
      child.parentData = _CarouselParentData();
    }
  }

  // TODO: add intrinsics

  @override
  void performLayout() {
    assert(constraints.hasBoundedWidth);
    assert(constraints.hasBoundedHeight);

    final width = constraints.maxWidth;
    final height = constraints.maxHeight;
    final childConstraints = BoxConstraints(
      minWidth: 0.0,
      maxWidth: double.infinity,
      minHeight: height,
      maxHeight: height,
    );

    final centerPoints = <Offset>[];
    int index = 0;
    double contentWidth = 0.0;
    RenderBox child = firstChild;
    while (child != null) {
      final childParentData = child.parentData as _CarouselParentData;
      child.layout(childConstraints, parentUsesSize: true);
      if (index == 0) {
        contentWidth += (width - child.size.width) / 2;
      }
      childParentData.offset = Offset(contentWidth, 0.0);
      contentWidth += child.size.width;
      centerPoints.add((childParentData.offset & child.size).center);
      if (childParentData.nextSibling == null) {
        contentWidth += (width - child.size.width) / 2;
      }
      child = childParentData.nextSibling;
      index++;
    }
    _controller.centerPoints = centerPoints;

    _offset.applyViewportDimension(width);
    _offset.applyContentDimensions(0.0, max(contentWidth - width, 0.0));

    size = Size(width, height);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {Offset position}) {
    position = (position ?? Offset.zero) + Offset(_offset.pixels, 0.0);
    return defaultHitTestChildren(result, position: position);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    defaultPaint(context, offset + Offset(-_offset.pixels, 0.0));
  }

  @override
  void applyPaintTransform(RenderObject child, Matrix4 transform) {
    super.applyPaintTransform(child, transform);
    transform.translate(-_offset.pixels, 0.0);
  }
}

class _CarouselParentData extends ContainerBoxParentData<RenderBox> {
  //
}
