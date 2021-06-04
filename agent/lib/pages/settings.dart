

// settings page


import 'package:flutter/material.dart';
import 'package:flutter_zoekits/flutter_zoekits.dart';
import 'package:velocity_x/velocity_x.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("设置"),
        centerTitle: true,
      ),
      body: VxBox(
        child: <Widget>[

          TextButton.icon(
            onPressed: () => {},
            icon: Icon(Icons.access_alarm), label: "测试".text.make()),

          ZButton(busying: true),
          ZButton(child: "测试自动繁忙".text.make(), onPressed: () async {
            await Future.delayed(Duration(seconds: 2));
          }),
          ZButton(child: "测试".text.make(), onPressed: () => {}, type: ButtonType.Elevated),
          ZButton(child: "测试".text.make(), onPressed: () => {}, type: ButtonType.Outlined),
          ZButton(child: "测试".text.make(), onPressed: () => {}, type: ButtonType.Text),
          ZButton(child: "测试".text.make(), onPressed: () => {}, rounded: false),
          ZButton(child: "测试".text.make(), onPressed: () => {}, disabled: true),
        ].vStack()
      ).makeCentered(),
    );
  }
}