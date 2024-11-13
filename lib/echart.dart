import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_echarts/flutter_echarts.dart';

class RandomChartContainer extends StatefulWidget {
  @override
  _RandomChartContainerState createState() => _RandomChartContainerState();
}

class _RandomChartContainerState extends State<RandomChartContainer> {
  List<List<double>> _chartData = [];
  List<String> _xAxisData = [];
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _generateRandomData();
    // Start a timer to update data every 2 seconds
    _timer = Timer.periodic(Duration(seconds: 2), (timer) {
      _generateRandomData();
    });
  }

  void _generateRandomData() {
    final random = Random();

    setState(() {
      // Generate x-axis data with current date and previous 4 days
      _xAxisData = List.generate(5, (index) {
        final date = DateTime.now().subtract(Duration(days: 4 - index));
        return '${date.toLocal().toIso8601String().split('T').first}';
      });

      // Generate random candlestick data and colors
      _chartData = List.generate(5, (index) {
        final open = random.nextDouble() * 20 + 10;
        final close = open + (random.nextDouble() * 10 - 5);
        final low = min(open, close) - random.nextDouble() * 5;
        final high = max(open, close) + random.nextDouble() * 5;

        return [open, close, low, high];
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Convert chart data to match Echarts' expected format
    final seriesData = '''
    {
      name: 'Candlestick',
      type: 'candlestick',
      data: ${jsonEncode(_chartData)},
      itemStyle: {
        color: '#00c853',
        color0: '#d50032',
        borderColor: '#00c853',
        borderColor0: '#d50032'
      }
    }
    ''';

    return Container(
      height: 300.h, // Adjust height based on your design
      padding: const EdgeInsets.all(16.0),
      child: Echarts(
        captureAllGestures: true,
        option: '''
        {
          title: {
            text: 'Candlestick Chart'
          },
          tooltip: {
            trigger: 'axis',
            axisPointer: {
              type: 'cross'
            }
          },
          legend: {
            data: ['Candlestick']
          },
          xAxis: {
            type: 'category',
            data: ${jsonEncode(_xAxisData)},
            scale: true,
            boundaryGap: false,
            axisLine: { onZero: false }
          },
          yAxis: {
            scale: true,
            axisLine: { onZero: false }
          },
          
          series: [
            $seriesData
            
          ]
        }
        ''',
      ),
    );
  }
}
