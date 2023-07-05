import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pool Status',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Pool Status'),
    );
  }
}

class TempData {
  final double time;
  final double temp;

  TempData(this.time, this.temp);
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _heaterStatus = false;
  bool _pumpStatus = false;
  late Future<List<TempData>> futureTempData;
  late Future<String> futureTemperature;

  @override
  void initState() {
    super.initState();
    futureTempData = _fetchData();
    futureTemperature = _fetchCurrentTemperature();
  }

  Future<String> _fetchCurrentTemperature() async {
    final response =
        await http.get(Uri.parse('http://192.168.50.242:5000/getTemperature'));
    if (response.statusCode == 200) {
      Map<String, dynamic> data = jsonDecode(response.body);
      return data['data'];
    } else {
      throw Exception('Failed to load current temperature data');
    }
  }

  Future<List<TempData>> _fetchData() async {
    final response =
        await http.get(Uri.parse('http://192.168.50.242:5000/getPastTempData'));
    if (response.statusCode == 200) {
      List<TempData> list = [];
      List<String> strList = response.body.split('\n');
      strList.removeLast();
      for (var str in strList) {
        List<String> tempAndTime = str.split(',');
        double temp = double.parse(tempAndTime[0]);
        double time = double.parse(tempAndTime[1]) - 1687088005.0;
        list.add(TempData(time, temp));
      }
      return list;
    } else {
      throw Exception('Failed to load temperature data');
    }
  }

  void _toggleHeater() {
    setState(() {
      _heaterStatus = !_heaterStatus;
    });
  }

  void _togglePump() {
    setState(() {
      _pumpStatus = !_pumpStatus;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              FutureBuilder<String>(
                future: futureTemperature,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return Text(
                      'Pool temperature is ${snapshot.data} degrees',
                      style: Theme.of(context).textTheme.headlineMedium,
                    );
                  } else if (snapshot.hasError) {
                    return Text("${snapshot.error}");
                  }
                  return const CircularProgressIndicator();
                },
              ),
              Text(
                'Heater is ${_heaterStatus ? "ON" : "OFF"}',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              Text(
                'Pump is ${_pumpStatus ? "ON" : "OFF"}',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              ElevatedButton(
                onPressed: _toggleHeater,
                child: const Text('Toggle Heater'),
              ),
              ElevatedButton(
                onPressed: _togglePump,
                child: const Text('Toggle Pump'),
              ),
              const SizedBox(height: 16.0),
              FutureBuilder<List<TempData>>(
                future: futureTempData,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    List<FlSpot> spots = snapshot.data!
                        .map((tempData) => FlSpot(tempData.time, tempData.temp))
                        .toList();
                    double minY = 17;
                    double maxY = 20;

                    return SizedBox(
                      height: 300.0,
                      child: LineChart(
                        LineChartData(
                          minX: spots.first.x,
                          maxX: spots.last.x,
                          minY: minY,
                          maxY: maxY,
                          lineBarsData: [
                            LineChartBarData(
                              spots: spots,
                              isCurved: true,
                              dotData: const FlDotData(show: false),
                            ),
                          ],
                          titlesData: const FlTitlesData(show: true),
                          gridData: const FlGridData(show: false),
                          borderData: FlBorderData(show: false),
                          lineTouchData: const LineTouchData(enabled: false),
                        ),
                      ),
                    );
                  } else if (snapshot.hasError) {
                    return Text("${snapshot.error}");
                  }
                  return const CircularProgressIndicator();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
