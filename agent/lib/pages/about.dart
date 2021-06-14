import 'package:flutter/material.dart';
import 'package:flutter_zoekits/flutter_zoekits.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({ Key key }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AboutView(
      logo: "assets/logos/main.png",
      title: "易付",
      description: "让个人支付收款更简单",
      links: [
        LabelURL("用户协议", "https://m.baidu.com"),
        LabelURL("隐私政策", "https://m.baidu.com"),
        LabelURL("用户规范", "https://m.baidu.com"),
      ],
      copyright: "易付公司 版权所有",
    ).page(title: "关于");
  }
}