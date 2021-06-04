

// analytics page

import 'package:flutter/material.dart';
import 'package:flutter_zoekits/flutter_zoekits.dart';
import 'package:velocity_x/velocity_x.dart';

class AnalyticsPage extends StatefulWidget {
  @override
  _AnalyticsPageState createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("统计"),
        centerTitle: true,
        bottom: [
          [
            ZButton(child: "日".text.make(), onPressed: () => {}, rounded: false).box.width(36).make(),
            ZButton(child: "周".text.make(), onPressed: () => {}, rounded: false).box.width(36).make(),
            ZButton(child: "月".text.make(), onPressed: () => {}, rounded: false).box.width(36).make(),
          ].hStack(alignment: MainAxisAlignment.spaceAround,).expand(flex: 1),

          ZButton(child: "选择日期".text.make(), onPressed: () => {}).expand(flex: 1),
        ].hStack(
          alignment: MainAxisAlignment.spaceBetween,
          axisSize: MainAxisSize.max,
        ).box.color(Colors.white).height(50).px8.make()
        .preferredSize(Size.fromHeight(50)),
      ),
      body: SingleChildScrollView(
        // child: [
        //   VxCard("交易金额".text.make()).p16.rounded.make().box.px8.height(240).width(double.infinity).make(),
        //   VxCard("订单数量".text.make()).p16.rounded.make().box.px8.height(240).width(double.infinity).make(),
        //   VxCard("订单均价".text.make()).p16.rounded.make().box.px8.height(240).width(double.infinity).make(),
        // ].vStack().expand(),
      ),
    );
  }
}