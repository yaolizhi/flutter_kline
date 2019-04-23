/*
 * @Description: 
 * @Author: zhaojijin
 * @LastEditors: Please set LastEditors
 * @Date: 2019-04-16 11:08:20
 * @LastEditTime: 2019-04-23 15:05:39
 */
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_kline/packages/bloc/klineBloc.dart';
import 'package:flutter_kline/packages/bloc/klineBlocProvider.dart';
import 'package:flutter_kline/packages/model/klineConstrants.dart';
import 'package:flutter_kline/packages/model/klineModel.dart';
import 'package:flutter_kline/packages/view/klineWidget.dart';

class KlinePage extends StatelessWidget {
  final KlineBloc bloc;
  KlinePage({Key key, @required this.bloc}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    Offset lastPoint;
    bool isScale = false;
    bool isLongPress = false;
    bool isHorizontalDrag = false;
    double screenWidth = MediaQuery.of(context).size.width;
    _showCrossWidget(Offset offset) {
      if (isScale || isHorizontalDrag) {
        return;
      }
      isLongPress = true;
      int singleScreenCandleCount = bloc.getSingleScreenCandleCount(screenWidth);
      int offsetCount =
          ((offset.dx / screenWidth) * singleScreenCandleCount).toInt();
      print(
          'offsetCount :$offsetCount length: ${bloc.klineCurrentList.length}');
      if (offsetCount > bloc.klineCurrentList.length - 1) {
        return;
      }
      int index = bloc.klineCurrentList.length - 1 - offsetCount;
      // print(
          // 'offsetCount :$offsetCount index :$index length: ${bloc.klineCurrentList.length}');
      if (index < bloc.klineCurrentList.length) {
        Market market = bloc.klineCurrentList[index];
        // market.printDesc();
        market.isShowCandleInfo = true;
        bloc.marketSinkAdd(market);
      }
    }

    _hiddenCrossWidget() {
      isLongPress = false;
      bloc.marketSinkAdd(
          Market(null, null, null, null, null, isShowCandleInfo: false));
    }

    _horizontalDrag(Offset offset) {
      if (isScale || isLongPress) {
        return;
      }
      double offsetX = offset.dx - lastPoint.dx;
      int singleScreenCandleCount = bloc.getSingleScreenCandleCount(screenWidth);
      // 当前偏移的个数
      int offsetCount =
          ((offsetX / screenWidth) * singleScreenCandleCount).toInt();
      if (offsetCount == 0) {
        return;
      }
      int firstScreenNum =
          (singleScreenCandleCount * bloc.getFirstScreenScale()).toInt();
      if (bloc.klineTotalList.length > firstScreenNum) {
        // 当前总的偏移个数
        int currentOffsetCount = bloc.toIndex + offsetCount;
        int totalListLength = bloc.klineTotalList.length;
        currentOffsetCount = min(currentOffsetCount, totalListLength);
        if (currentOffsetCount < firstScreenNum) {
          return;
        }
        int fromIndex = 0;
        print('fromIndex: $fromIndex');
        
        // 如果当前偏移的个数 没有达到一屏所展示的个数则从0开始取数据
        if (currentOffsetCount > singleScreenCandleCount) {
          fromIndex = (currentOffsetCount - singleScreenCandleCount);
        }
        lastPoint = offset;
        bloc.getSubKlineList(fromIndex, currentOffsetCount);
        print('fromIndex: $fromIndex  currentOffsetCount: $currentOffsetCount');
      }
    }

    _scaleUpdate(double scale) {
      if (isHorizontalDrag || isLongPress) {
        return;
      }
      // if ((scale-1).abs() > 0.02) {
      //   scale += 0.02;
      // }
      isScale = true;
      if (scale > 1 && (scale - 1) > 0.03) {
        scale = 1.03;
      } else if (scale < 1 && (1 - scale) > 0.03) {
        scale = 0.97;
      }
      double candlestickWidth = scale * bloc.candlestickWidth;
      bloc.setCandlestickWidth(candlestickWidth);
      // print('bloc.candlestickWidth : ${bloc.candlestickWidth}');
      double count = (screenWidth - bloc.candlestickWidth) /
          (kCandlestickGap + bloc.candlestickWidth);
      int currentScreenCountNum = count.toInt();

      int toIndex = bloc.toIndex;
      int fromIndex = toIndex - currentScreenCountNum;
      fromIndex = max(0, fromIndex);

      print(
          'from: $fromIndex   to: $toIndex  currentScreenCountNum: $currentScreenCountNum');
      bloc.getSubKlineList(fromIndex, toIndex);
    }

    return KlineBlocProvider<KlineBloc>(
      bloc: bloc,
      child: GestureDetector(
        /// 长按
        onLongPressDragStart: (longPressDragStartDetail) {
          _showCrossWidget(longPressDragStartDetail.globalPosition);
          print('onLongPressDragStart');
        },
        onLongPressDragUpdate: (longPressDragUpdateDetail) {
          _showCrossWidget(longPressDragUpdateDetail.globalPosition);
          print('onLongPressDragUpdate');
        },
        onLongPressDragUp: (longPressDragUpDetail) {
          _hiddenCrossWidget();
          print('onLongPressDragUp');
        },
        
        /// 水平拖拽
        onHorizontalDragDown: (horizontalDragDown) {
          isHorizontalDrag = true;
          lastPoint = horizontalDragDown.globalPosition;
        },
        // onHorizontalDragStart: (details) {
        //   isHorizontalDrag = true;
        //   lastPoint = details.globalPosition;
        // },
        onHorizontalDragUpdate: (details) {
          _horizontalDrag(details.globalPosition);
        },
        onHorizontalDragEnd: (_) {
          isHorizontalDrag = false;
        },
        onHorizontalDragCancel: () {
          isHorizontalDrag = false;
        },

        /// 缩放
        onScaleUpdate: (details) {
          _scaleUpdate(details.scale);
        },
        onScaleEnd: (_) {
          isScale = false;
        },

        child: StreamBuilder(
          stream: bloc.klineListStream,
          builder:
              (BuildContext context, AsyncSnapshot<List<Market>> snapshot) {
            List<Market> listData = snapshot.data;
            if (listData != null) {
              bloc.setScreenWidth(screenWidth);
            }
            return KlineWidget();
          },
        ),
      ),
    );
  }
}