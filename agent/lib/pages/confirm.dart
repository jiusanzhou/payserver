import 'package:flutter/material.dart';
import 'package:velocity_x/velocity_x.dart';

class ConfirmPage extends StatefulWidget {
  @override
  _ConfirmPageState createState() => _ConfirmPageState();
}

class _ConfirmPageState extends State<ConfirmPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: "确认订单".text.make(),
        centerTitle: true,
      ),
    );
  }
}