


import 'package:agent/models/transaction.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_notification_listener/flutter_notification_listener.dart';
import 'package:provider/provider.dart';
import 'package:velocity_x/velocity_x.dart';

class StatePanel extends StatefulWidget {
  @override
  _StatePanelState createState() => _StatePanelState();
}

class _StatePanelState extends State<StatePanel> {

  double circleSize = 150;

  bool _busying = false;
  bool _started = false;

  PayTransactionModel _model;

  @override
  void initState() {
    super.initState();

    SchedulerBinding.instance.addPostFrameCallback((_) async {
      var isR = await NotificationsListener.isRunning;
      setState(() => _started = isR);
    });
  }

  void _onTap() async {

    // alert dialog
    if (!await NotificationsListener.hasPermission) {
      NotificationsListener.openPermissionSettings();
      return;
    }

    if (_busying) return;

    // start / stop
    setState(() {
      _busying = true;
    });

    if (!_started) {
      await NotificationsListener.startService();
    } else {
      await NotificationsListener.stopService();
    }

    setState(() {
      _busying = false;
      _started = !_started;
    });

  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PayTransactionModel>(
      builder: (context, model, child) {
        if (_model == null) _model = model;
        return [
          VxBox().height(70).make(), // place holder
          (_busying
          // TODO: animation
          ? Icon(Icons.loop, color: Colors.white, size: circleSize / 3) // CircularProgressIndicator(backgroundColor: Vx.teal100, strokeWidth: 3)
          : _started
          ? Icon(Icons.check, color: Colors.white, size: circleSize / 3)
          : Icon(Icons.power_settings_new, color: Colors.white, size: circleSize / 3))
            .box.size(circleSize, circleSize).teal600
            .border(color: Vx.teal100, width: 10)
            .roundedFull.make().onInkTap(_onTap),
          (_busying
          ? "处理中..."
          : _started
          ? "运行中，点击按钮关闭收款!"
          : "未运行，点击按钮开始收款~").text.bold.white.make().box.margin(Vx.mV8).make(),
          [
            StateItem("今日笔数", unit: "笔", value: model.todayCount, color: Vx.teal600, icon: Icons.check_circle),
            StateItem("今日金额", unit: "元", value: (model.todayAmount/100).toStringAsFixed(2), color: Vx.green600, icon: Icons.monetization_on),
            StateItem("待确认数", unit: "单", value: model.waitConfirm, color: Vx.red600, icon: Icons.help)
              .onInkTap(() => Navigator.of(context).pushNamed("/confirm")),
          ].hStack(alignment: MainAxisAlignment.spaceAround)
              .box.height(80).px8.width(MediaQuery.of(context).size.width * 0.85).color(Colors.white.withAlpha(220)).rounded.make(),
        ].vStack().centered();
      }
    );
  }
}

class StateItem extends StatelessWidget {

  final String label;
  final dynamic value;
  final IconData icon;
  final String unit;
  final Color color;

  StateItem(this.label, { this.icon = Icons.public, this.unit="", this.value="0", this.color});

  @override
  Widget build(BuildContext context) {
    return VxBox(
      child: <Widget>[
        <Widget>[
          "$value".text.color(color).bold.size(24).make(),
          unit.text.bold.size(14).make().box.margin(Vx.mOnly(left: 4)).make(),
        ].hStack(),
        VxBox().height(6).make(),
        <Widget>[
          Icon(icon, size: 12).box.margin(Vx.mOnly(right: 2)).make(),
          label.text.size(12).make(),
        ].hStack(alignment: MainAxisAlignment.center, crossAlignment: CrossAxisAlignment.center),
      ].vStack(),
    ).make();
  }
}