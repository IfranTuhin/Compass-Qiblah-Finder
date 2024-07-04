
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const platform = MethodChannel('compassApp/compass');
  double _direction = 0;
  double _qiblaDirection = 0;
  double _alpha = 0.1; // Low-pass filter constant

  @override
  void initState() {
    super.initState();
    _startCompass();
    _getQiblaDirection();
  }

  void _startCompass() {
    Timer.periodic(const Duration(milliseconds: 100), (timer) async {
      final double direction = await platform.invokeMethod('getCompassOrientation');
      setState(() {
        _direction = _lowPassFilter(_direction, direction);
      });
    });
  }

  Future<void> _getQiblaDirection() async {
    final List<dynamic> location = await platform.invokeMethod('getCurrentLocation');
    final double latitude = location[0];
    final double longitude = location[1];
    final double qiblaDirection = _calculateQiblaDirection(latitude, longitude);
    setState(() {
      _qiblaDirection = qiblaDirection;
    });
  }

  double _calculateQiblaDirection(double lat, double lng) {
    const double meccaLat = 21.4225;
    const double meccaLng = 39.8262;

    const double phiK = meccaLat * pi / 180.0;
    const double lambdaK = meccaLng * pi / 180.0;
    final double phi = lat * pi / 180.0;
    final double lambda = lng * pi / 180.0;

    final double qibla = (atan2(sin(lambdaK - lambda), cos(phi) * tan(phiK) - sin(phi) * cos(lambdaK - lambda))) * 180.0 / pi;
    return (qibla + 360) % 360;
  }

  double _lowPassFilter(double oldValue, double newValue) {
    return oldValue + _alpha * (newValue - oldValue);
  }

  @override
  Widget build(BuildContext context) {

    // Screen size
    var screenSize = MediaQuery.of(context).size;

    return Scaffold(
      body: SafeArea(
        child: Container(
          height: screenSize.height,
          width: screenSize.width,
          decoration: const  BoxDecoration(
            color: Color.fromRGBO(239, 229, 223, 1),
            image: DecorationImage(
              image: AssetImage('assets/images/flower-pattern-bg.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: Column(
            children: [
              // ------>  Left & Right corner image  <---------
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Image.asset('assets/images/left_corner.png'),
                  Image.asset('assets/images/right_corner.png'),
                ],
              ),
              const SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(15),
                  color: Colors.green,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Qibla Finder', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Colors.white)),
                          SizedBox(height: 5),
                          Text('Find Qibla direction any\nwhere with 100% accuracy', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  Transform.rotate(
                    angle: (_direction * (pi / 180) * -1),
                    child: Image.asset(
                      'assets/images/Compass.png',
                      height: 300,
                    ),
                  ),
                  Transform.rotate(
                    angle: ((_direction - _qiblaDirection) * (pi / 180) * -1),
                    child: Image.asset('assets/images/Compas-kata.png'),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              Text('Compass Direction : ${_direction.toStringAsFixed(1)}°', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
              Text('Qiblah Direction : ${_qiblaDirection.toStringAsFixed(1)}°',style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),

            ],
          ),
        ),
      ),
    );
  }
}