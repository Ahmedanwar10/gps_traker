import 'package:flutter/material.dart';
import 'package:gps_tracker/home/home_view_body.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('GPS Tracker'),
      ),
      body:  HomeViewBody(),
    );
  }
}