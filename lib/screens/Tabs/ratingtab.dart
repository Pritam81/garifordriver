import 'package:flutter/material.dart';

class RatingTab extends StatefulWidget {
  const RatingTab({super.key});

  @override
  State<RatingTab> createState() => _RatingTabState();
}

class _RatingTabState extends State<RatingTab> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Rating Tab',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    );
  }
}
