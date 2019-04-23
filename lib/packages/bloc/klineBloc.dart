/*
 * @Description: 
 * @Author: zhaojijin
 * @LastEditors: Please set LastEditors
 * @Date: 2019-04-16 15:02:34
 * @LastEditTime: 2019-04-22 14:54:47
 */
import 'dart:math';

import 'package:flutter_kline/packages/bloc/klineBlocProvider.dart';
import 'package:flutter_kline/packages/manager/klineDataManager.dart';
import 'package:flutter_kline/packages/model/klineDataModel.dart';
import 'package:flutter_kline/packages/model/klineModel.dart';
import 'package:flutter_kline/packages/model/klineConstrants.dart';
import 'package:rxdart/rxdart.dart';

class KlineBloc extends KlineBlocBase {
  // 总数据的流入流出
  BehaviorSubject<List<Market>> _klineListSubject =
      BehaviorSubject<List<Market>>();
  Sink<List<Market>> get _klineListSink => _klineListSubject.sink;
  Stream<List<Market>> get klineListStream => _klineListSubject.stream;

  // 当前数据的流入流出
  PublishSubject<List<Market>> _klineCurrentListSubject =
      PublishSubject<List<Market>>();
  Sink<List<Market>> get _currentKlineListSink => _klineCurrentListSubject.sink;
  Stream<List<Market>> get currentKlineListStream =>
      _klineCurrentListSubject.stream;

  // 点击获取单条k线数据
  PublishSubject<Market> _klineMarketSubject = PublishSubject<Market>();
  Sink<Market> get _klineMarketSink => _klineMarketSubject.sink;
  Stream<Market> get klineMarketStream => _klineMarketSubject.stream;

  /// 单屏显示的kline数据
  List<Market> klineCurrentList = List();

  /// 总数据
  List<Market> klineTotalList = List();

  double screenWidth = 375;
  double priceMax;
  double priceMin;
  double volumeMax;
  int firstScreenCandleCount;
  double candlestickWidth = kCandlestickWidth;

  /// 当前K线滑到的起点位置
  int fromIndex;

  /// 当前K线滑到的终点位置
  int toIndex;

  KlineBloc() {
    initData();
  }

  void initData() {}

  @override
  void dispose() {
    _klineListSubject.close();
    _klineCurrentListSubject.close();
    _klineMarketSubject.close();
  }

  void updateDataList(List<KlineDataModel> dataList) {
    if (dataList != null && dataList.length > 0) {
      klineTotalList.clear();
      for (var item in dataList) {
        Market data =
            Market(item.open, item.high, item.low, item.close, item.vol);
        klineTotalList.add(data);
      }
      klineTotalList =
          KlineDataManager.calculateKlineData(YKChartType.MA, klineTotalList);
      // klineTotalList = [klineTotalList.first];
      _klineListSink.add(klineTotalList);
    }
  }

  void setCandlestickWidth(double scaleWidth) {
    if (scaleWidth > 25 || scaleWidth < 2) {
      return;
    }
    candlestickWidth = scaleWidth;
  }

  int getSingleScreenCandleCount(double width) {
    screenWidth = width;
    double count =
        (screenWidth - kCandlestickGap) / (candlestickWidth + kCandlestickGap);
    int totalScreenCountNum = count.toInt();
    return totalScreenCountNum;
  }

  double getFirstScreenScale() {
    return (kGridColumCount - 1) / kGridColumCount;
  }

  void setScreenWidth(double width) {
    screenWidth = width;
    int singleScreenCandleCount = getSingleScreenCandleCount(screenWidth);
    int maxCount = this.klineTotalList.length;
    int firstScreenNum =
        (getFirstScreenScale() * singleScreenCandleCount).toInt();
    if (singleScreenCandleCount > maxCount) {
      firstScreenNum = maxCount;
    }
    firstScreenCandleCount = firstScreenNum;

    getSubKlineList(0, firstScreenCandleCount);
  }

  void getSubKlineList(int from, int to) {
    fromIndex = from;
    toIndex = to;
    List<Market> list = this.klineTotalList;
    klineCurrentList.clear();
    klineCurrentList = list.sublist(from, to);
    _calculateCurrentKlineDataLimit();
    _currentKlineListSink.add(klineCurrentList);
  }

  void _calculateCurrentKlineDataLimit() {
    double _priceMax = -double.infinity;
    double _priceMin = double.infinity;
    double _volumeMax = -double.infinity;
    for (var item in klineCurrentList) {
      _volumeMax = max(item.vol, _volumeMax);

      _priceMax = max(_priceMax, item.high);
      _priceMin = min(_priceMin, item.low);

      /// 与x日均线数据对比计算最高最低价格
      if (item.priceMa1 != null) {
        _priceMax = max(_priceMax, item.priceMa1);
        _priceMin = min(_priceMin, item.priceMa1);
      }
      if (item.priceMa2 != null) {
        _priceMax = max(_priceMax, item.priceMa2);
        _priceMin = min(_priceMin, item.priceMa2);
      }
      if (item.priceMa3 != null) {
        _priceMax = max(_priceMax, item.priceMa3);
        _priceMin = min(_priceMin, item.priceMa3);
      }
      priceMax = _priceMax;
      priceMin = _priceMin;
      volumeMax = _volumeMax;

      // print('priceMax : $priceMax');
      // print('priceMax : $priceMax priceMin: $priceMin volumeMax: $volumeMax');
    }
  }

  void marketSinkAdd(Market market) {
    if (market != null) {
      _klineMarketSink.add(market);
    }
  }
}