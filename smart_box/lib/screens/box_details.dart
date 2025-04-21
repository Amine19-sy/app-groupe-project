import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_box/bloc/cubits/items_cubits.dart';
import 'package:smart_box/models/box.dart';
import 'package:smart_box/screens/history.dart';
import 'package:smart_box/screens/items.dart';
import 'package:smart_box/screens/temp.dart';
import 'package:pretty_gauge/pretty_gauge.dart';
import 'package:smart_box/services/item_service.dart';
import 'package:fl_chart/fl_chart.dart';




class BoxDetails extends StatefulWidget {
  final Box box;
  final Map<String, dynamic> user;
  const BoxDetails({super.key, required this.box, required this.user});

  @override
  State<BoxDetails> createState() => _BoxDetailsState();
}

class _BoxDetailsState extends State<BoxDetails> {
  int _selectedIndex = 0;
  final List<FlSpot> sampleData = [
  FlSpot(0, 1.5),
  FlSpot(1, 1.7),
  FlSpot(2, 1.4),
  FlSpot(3, 1.8),
  FlSpot(4, 1.6),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _pages = <Widget>[
      BoxHeader(boxName: widget.box.name,boxDesc: widget.box.description,),
      BlocProvider(
        create: (_) => ItemsCubit(ItemService())..getItems(widget.box.id),
        child: Items(boxId: widget.box.id,userId: widget.user["user"]["id"],),
      ),
      HistoryPage(boxId: widget.box.id,),
      MyLineChart(dataPoints: sampleData,)
      // Center(
      //   child: PrettyGauge(
      //     gaugeSize: 200,
      //     segments: [
      //       GaugeSegment('Low', 20, Colors.red),
      //       GaugeSegment('Medium', 40, Colors.orange),
      //       GaugeSegment('High', 40, Colors.green),
      //     ],
      //     currentValue: 46,
      //     displayWidget: Text('Temperature', style: TextStyle(fontSize: 12)),
      //   ),
      // )

      // TemperatureScreen(),
    ];
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "Details",
          textAlign: TextAlign.center,
        ),
        backgroundColor: Colors.white,
      ),
      body: IndexedStack(
      
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            backgroundColor: Colors.white,
            icon: Icon(Icons.home),
            label: 'Info',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Items',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fireplace),
            label: 'Temperature',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.black,
        onTap: _onItemTapped,
        
      ),
    );
  }
}

class BoxHeader extends StatefulWidget {
  final String boxName;
  final String boxDesc;

  const BoxHeader({
    Key? key,
    required this.boxName,
    required this.boxDesc,
  }) : super(key: key);

  @override
  State<BoxHeader> createState() => _BoxHeaderState();
}

class _BoxHeaderState extends State<BoxHeader> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Top colored section with icon and box name
          Stack(
            children: [
              Container(
                height: 200,
                width: double.infinity,
                color: Colors.blueAccent,
              ),
              Container(
                height: 200,
                width: double.infinity,
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star,
                      size: 60,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.boxName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Description in the remaining space
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Text(
                  widget.boxDesc,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MyLineChart extends StatelessWidget {
  final List<FlSpot> dataPoints;
  
  const MyLineChart({ Key? key, required this.dataPoints }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(child: Container(height: 300,width: 300,child:LineChart(
  LineChartData(
    lineBarsData: [
      // ... your LineChartBarData here
      LineChartBarData(
              spots: dataPoints,
              isCurved: true,
              barWidth: 3,
              dotData: FlDotData(show: true),
            ),
    ],
    titlesData: FlTitlesData(
      // Wrap your SideTitles in AxisTitles:
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: (value, meta) {
            // value is the x-position
            return Text(value.toInt().toString());
          },
          reservedSize: 32,
        ),
      ),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: (value, meta) {
            // value is the y-position
            return Text(value.toString());
          },
          reservedSize: 40,
        ),
      ),
      rightTitles: AxisTitles(
        sideTitles: SideTitles(showTitles: false),
      ),
      topTitles: AxisTitles(
        sideTitles: SideTitles(showTitles: false),
      ),
    ),
    gridData: FlGridData(show: true),
    borderData: FlBorderData(show: true),
    // ... other properties (e.g. lineTouchData)
  ),
)),),
    );

  }
}

