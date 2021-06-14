

// settings page


import 'package:agent/styles/colors.dart';
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
      backgroundColor: Colours.bgLight,
      /**
       *   Color(0xff788aa9), Color(0xfff6bd16),
            Color(0xff5ad8a6), Color(0xff6dc8ec),
            Color(0xff7ca5fa), Color(0xff074bd5),
       */
      body: SingleChildScrollView(
        child: [
          [
            Menu(
              icon: Icons.public,
              title: "服务管理",
              to: "/servers",
              primary: Color(0xff074bd5),
            ),
            Menu(
              icon: Icons.cloud_queue,
              title: "收款统计",
              to: "/analytics",
              primary: Color(0xff5ad8a6),
            ),
            Menu(
              icon: Icons.wifi_tethering,
              title: "收款记录",
              primary: Color(0xfff6bd16),
              onTap: () => Navigator.of(context).pop(),
            ),
            Menu(
              icon: Icons.bug_report,
              title: "调试页面",
              primary: Color(0xfff6bd16),
              to: "/test"
            ),
          ].blockGroup(
            Menu(
              title: "其他内容",
              background: Colors.white,
              itemType: MenuItemViewType.Grid,
            ),
            gridHeight: 152,
            gridChildAspectRatio: 1.5,
          ),

          [
            Menu(
              icon: Icons.public,
              title: "服务管理",
              to: "/servers",
              primary: Color(0xff074bd5),
            ),
            Menu(
              icon: Icons.cloud_queue,
              title: "收款统计",
              to: "/analytics",
              primary: Color(0xff5ad8a6),
            ),
            Menu(
              icon: Icons.wifi_tethering,
              title: "收款记录",
              primary: Color(0xfff6bd16),
              onTap: () => Navigator.of(context).pop(),
            ),
            Menu(
              icon: Icons.error,
              title: "调试页面",
              primary: Color(0xfff6bd16),
              to: "/test",
            ),
          ].pageGroup(
            Menu(
              title: "其他内容",
              description: "关于其他项目的内容，需要单独进行说明",
              icon: Icons.public,
              background: Colors.white,
              primary: Color(0xff5ad8a6),
              itemType: MenuItemViewType.Tile, // TODO: support grid
            ),
            separated: true
          ),
          Menu(
            title: "关于",
            icon: Icons.new_releases,
            background: Colors.white,
            to: "/about",
          ),
          // .margin(EdgeInsets.only(bottom: 20))
        ].make(separator: VxBox().height(10).make(), separated: true),
      )
    );
  }
}