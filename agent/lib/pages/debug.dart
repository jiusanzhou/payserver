
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:flutter_zoekits/flutter_zoekits.dart';

class DebugPage extends StatelessWidget {
  const DebugPage({ Key key }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: [
        ListTile(
          leading: Icon(Icons.access_alarms),
          title: "标题".text.make(),
          trailing: "结尾".text.make(),
          onTap: () {

          },
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(100)),
          ),
        ),
      ].vStack().box.p20.make().centered(),
    ).page(title: "测试页面");
  }
}