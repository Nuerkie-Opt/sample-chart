import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class TimePrices {
  final int time;
  final double price;

  TimePrices(this.time, this.price);
}

ValueNotifier<String> pointDate = ValueNotifier('');
String pointValue = '';
Color greenColor = const Color(0xFF28C9C3);
Color redColor = const Color(0xFFEF5B5B);
ValueNotifier<Color> lineAndBgColor = ValueNotifier(const Color(0xFF28C9C3));

class FetchData extends StatefulWidget {
  const FetchData({super.key});

  @override
  State<FetchData> createState() => _FetchDataState();
}

class _FetchDataState extends State<FetchData> {
  String currency = 'USD';
  double? currentPrice;
  ValueNotifier<String?> percentageChange = ValueNotifier('');
  ValueNotifier<List<FlSpot>?> chartData = ValueNotifier([]);
  List<Map<String, String>> cryptos = [
    {
      "name": "Bitcoin",
      "iso": "BTC",
    },
    {
      "name": "Tezos",
      "iso": "XTZ",
    },
    {
      "name": "Etheruem",
      "iso": "ETH",
    },
    {
      "name": "Solana",
      "iso": "SOL",
    },
    {
      "name": "Tron",
      "iso": "TRX",
    }
  ];
  List<Map<String, String>> timeDifferences = [
    {
      "buttonTitle": "1hr",
      "numberOfHours": "30",
      'timeValue': "minutes",
    },
    {
      "buttonTitle": "1D",
      "numberOfHours": "24",
      'timeValue': "hours",
    },
    {
      "buttonTitle": "1w",
      "numberOfHours": "7",
      'timeValue': "days",
    },
    {
      "buttonTitle": "1M",
      "numberOfHours": "30",
      'timeValue': "days",
    },
    {
      "buttonTitle": "6M",
      "numberOfHours": "4380",
      'timeValue': "minutes",
    },
    {
      "buttonTitle": "1Y",
      "numberOfHours": "52560",
      'timeValue': "minutes",
    }
  ];
  Map<String, String> selectedTimeDifference = {
    "buttonTitle": "1D",
    "numberOfHours": "24",
  };

  Future getData(
      {required String crypto,
      required String userPreferredLanguage,
      required String aggregate,
      required String timeValue,
      required String currency}) async {
    await APIUtils.getCryptoHistoricalData(
        crypto,
        crypto == 'EUR' ? 'EUR' : 'USD',
        userPreferredLanguage,
        aggregate,
        timeValue);
    List? cryptoSeries = [];
    List<FlSpot>? chartData;
    if (APIUtils.status) {
      List historicalPrice = APIUtils.data?['data'];
      cryptoSeries = historicalPrice.map((c) {
        double price = c['high'] * 1.0;

        return TimePrices(c['time'] * 1000, price);
      }).toList();
      num current;
      num compareTo;
      if (historicalPrice.first['time'] > historicalPrice[1]['time']) {
        current = historicalPrice.first['high'];
        compareTo = historicalPrice.last['high'];
      } else {
        current = historicalPrice.last['high'];
        compareTo = historicalPrice.first['high'];
      }

      currentPrice = current * 1.0;

      num change = (current - compareTo) / compareTo;
      num percentage = change * 100;
      if (current > compareTo) {
        lineAndBgColor.value = greenColor;
        percentageChange.value = "+${percentage.toStringAsFixed(2)}%";
      } else if (current < compareTo) {
        lineAndBgColor.value = redColor;
        percentageChange.value = "${percentage.toStringAsFixed(2)}%";
      } else {
        lineAndBgColor.value = greenColor;
        percentageChange.value = "+${percentage.toStringAsFixed(2)}%";
      }
    }

    if (cryptoSeries.isEmpty != true) {
      chartData = List<FlSpot>.generate(cryptoSeries.length, (index) {
        return FlSpot(
            cryptoSeries?[index].time.toDouble(), cryptoSeries?[index].price);
      });
      debugPrint('Done');
      return chartData;
    }
  }

  int randomIndex = Random().nextInt(5);
  Map<String, String>? selectedCrypto;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<bool>(
        future: (() async {
          selectedCrypto = cryptos[randomIndex];
          chartData.value = await getData(
              crypto: selectedCrypto!['iso'].toString(),
              currency: currency,
              timeValue: selectedTimeDifference['timeValue'].toString(),
              aggregate: selectedTimeDifference['numberOfHours'].toString(),
              userPreferredLanguage: 'en');
          if (chartData.value != null) {
            return true;
          } else {
            return false;
          }
          // return chartData?.value;
        })(),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.hasError) {
            return const Text('Could not fetch crypto prices');
          }
          if (snapshot.hasData) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    lineAndBgColor.value.withOpacity(0.4),
                    const Color(0xFFFAFAFA),
                    const Color(0xFFFAFAFA),
                    const Color(0xFFFAFAFA),
                    const Color(0xFFFAFAFA)
                  ],
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(
                    height: 50,
                  ),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => debugPrint('My back'),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF505AE9).withOpacity(0.05),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.keyboard_arrow_left,
                            color: Color(0xFF505AE9),
                          ),
                        ),
                      )
                    ],
                  ),
                  Text(
                    selectedCrypto!["name"].toString(),
                    style: const TextStyle(
                      color: Color(0xFF101561),
                      fontSize: 28.43,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  ListTile(
                    title: RichText(
                      text: TextSpan(
                        text: currentPrice.toString(),
                        style: const TextStyle(
                            color: Color(0xFF101561),
                            fontSize: 17.9,
                            fontWeight: FontWeight.w600),
                        children: [
                          TextSpan(
                              text: currency,
                              style: const TextStyle(
                                  color: Color(0xFF9FA1C0),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400))
                        ],
                      ),
                    ),
                    subtitle: Text(pointDate.value,
                        style: const TextStyle(
                            color: Color(0xFF9FA1C0),
                            fontSize: 14,
                            fontWeight: FontWeight.w400)),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                          color: lineAndBgColor.value,
                          borderRadius: BorderRadius.circular(15)),
                      child: Text(
                        percentageChange.value.toString(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: ChartRenderer(
                      chartData: chartData.value,
                      chartLineColor: Colors.green,
                      chartBgColor: Colors.transparent,
                    ),
                  ),
                  Row(
                    children: List.generate(timeDifferences.length, (index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: GestureDetector(
                          onTap: () async {
                            chartData.value = await getData(
                                crypto: selectedCrypto!['iso'].toString(),
                                currency: currency,
                                timeValue: timeDifferences[index]['timeValue']
                                    .toString(),
                                aggregate: timeDifferences[index]
                                        ['numberOfHours']
                                    .toString(),
                                userPreferredLanguage: 'en');
                            debugPrint('Test');
                            setState(() {
                              selectedTimeDifference = timeDifferences[index];
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 15, vertical: 10),
                            decoration: BoxDecoration(
                                color: selectedTimeDifference['buttonTitle'] ==
                                        timeDifferences[index]['buttonTitle']
                                    ? const Color(0xFF505AE9)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(
                                    selectedTimeDifference['buttonTitle'] ==
                                            timeDifferences[index]
                                                ['buttonTitle']
                                        ? 10
                                        : 0)),
                            child: Text(
                              timeDifferences[index]['buttonTitle'].toString(),
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight:
                                      selectedTimeDifference['buttonTitle'] ==
                                              timeDifferences[index]
                                                  ['buttonTitle']
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                  color:
                                      selectedTimeDifference['buttonTitle'] ==
                                              timeDifferences[index]
                                                  ['buttonTitle']
                                          ? Colors.white
                                          : const Color(0xFF101561)),
                            ),
                          ),
                        ),
                      );
                    }),
                  )
                ],
              ),
            );
          } else {
            return const Center(
              child: CircularProgressIndicator(
                color: Colors.green,
              ),
            );
          }
        },
      ),
    );
  }
}

class ChartRenderer extends StatefulWidget {
  final List<FlSpot>? chartData;
  final Color? chartLineColor;
  final Color? chartBgColor;
  const ChartRenderer(
      {super.key, this.chartData, this.chartLineColor, this.chartBgColor});

  @override
  State<ChartRenderer> createState() => _ChartRendererState();
}

class _ChartRendererState extends State<ChartRenderer> {
  @override
  void initState() {
    super.initState();
    pointDate.value = DateFormat.yMMMd().format(
        DateTime.fromMillisecondsSinceEpoch(
            widget.chartData?[(widget.chartData?.length as int) - 1].x.toInt()
                as int));
    pointValue = NumberFormat('#,##0.##').format(
      widget.chartData?[(widget.chartData?.length as int) - 1].y,
    );
    // walletGraph.setDateGraphSink.add(pointDate);
    // walletGraph.setValueGraphSink.add(pointValue);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          height: MediaQuery.of(context).size.height * 0.4,
          decoration: BoxDecoration(
            color: widget.chartBgColor ?? Colors.white,
          ),
          child: LineChart(
            mainData(widget.chartData, widget.chartLineColor),
            swapAnimationDuration: const Duration(milliseconds: 2000),
          ),
        ),
      ],
    );
  }

  LineChartData mainData(var data, var chartLineColor) {
    return LineChartData(
      lineTouchData: LineTouchData(
        enabled: true,
        //fullHeightTouchLine: true,
        handleBuiltInTouches: true,
        touchCallback: (FlTouchEvent touch, LineTouchResponse? response) {
          if (response == null) return;
          int x = response.lineBarSpots?.last.x.toInt() as int;
          pointValue =
              NumberFormat('#,##0.##').format(response.lineBarSpots?.last.y);
          setState(() {
            pointDate.value = DateFormat.yMMMd()
                .format(DateTime.fromMillisecondsSinceEpoch(x))
                .toString();

            //share the stream
            // walletGraph.setDateGraphSink.add(pointDate);
            // walletGraph.setValueGraphSink.add(pointValue);
          });
        },
        getTouchedSpotIndicator:
            (LineChartBarData barData, List<int> spotIndexes) {
          return spotIndexes.map((spotIndex) {
            return TouchedSpotIndicatorData(
              FlLine(
                  color: lineAndBgColor.value,
                  strokeWidth: 1,
                  dashArray: [3, 2]),
              FlDotData(),
            );
          }).toList();
        },
        touchTooltipData: LineTouchTooltipData(
          tooltipBgColor: lineAndBgColor.value,
          fitInsideHorizontally: true,
          fitInsideVertically: true,
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((e) {
              return LineTooltipItem(
                  pointValue, const TextStyle(color: Colors.white));
            }).toList();
          },
        ),
      ),
      gridData: FlGridData(
        show: false,
      ),
      titlesData: FlTitlesData(
        show: false,
      ),
      borderData: FlBorderData(
        show: false,
      ),
      lineBarsData: [
        LineChartBarData(
          spots: widget.chartData, //actualData(data),
          isCurved: true,
          color: lineAndBgColor.value,
          barWidth: 2,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: false,
          ),
          // belowBarData: BarAreaData(
          //   show: true,
          //   gradient:  LinearGradient(
          //     colors: [Color(0xFFFEF0EE), ProColors.ejaraBlue],
          //     stops: [0.1, 1.0],
          //     begin: Alignment.topCenter,
          //     end: Alignment.bottomCenter,
          //   ),
          // ),
        ),
      ],
    );
  }
}

class APIUtils {
  static bool status = false;
  static Map? data;

  static getCryptoHistoricalData(
      String crypto,
      String currency,
      String userPreferredLanguage,
      String aggregate,
      String endPointTimeValue) async {
    String endPoint = '/data/v2/histohour';
    if (endPointTimeValue == "days") {
      endPoint = '/data/v2/histoday';
    } else if (endPointTimeValue == "minutes") {
      endPoint = '/data/v2/histominute';
    } else {
      endPoint = '/data/v2/histohour';
    }
    status = false;
    var uri = Uri.https('min-api.cryptocompare.com', endPoint, {
      'fsym': crypto,
      'tsym': currency,
      'aggregate': aggregate,
      'limit': aggregate
    });
    http.Response response;
    try {
      response = await http.get(uri);
      if (response.statusCode == 200) {
        data = json.decode(response.body);
        if (data?['Response'] == 'Success') {
          status = true;
          data = {'data': data?['Data']['Data'], 'message': ''};
        } else {
          status = false;
          data = {'data': [], 'message': ''};
        }
      } else {
        status = false;
        data = json.decode(response.body);
      }
    } catch (e, s) {
      debugPrint(e.toString());
      debugPrint(s.toString());
      status = false;
      data = {
        'responsecode': 'request_error',
        'message': (userPreferredLanguage == 'en'
            ? "Please activate your internet connection and try again."
            : "Veuillez activer votre connexion Internet et réessayer")
      };
    }
  }
}
