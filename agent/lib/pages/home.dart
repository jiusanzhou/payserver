


// home page


import 'package:agent/models/server.dart';
import 'package:agent/models/models_test.dart';
import 'package:agent/styles/colors.dart';
import 'package:agent/views/panel.dart';
import 'package:agent/views/server_list.dart';
import 'package:agent/views/trans_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_zoekits/flutter_zoekits.dart';
import 'package:velocity_x/velocity_x.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

// state-controll panel
// transaction list

class _HomePageState extends State<HomePage> {

  var currentServer = genServer("官方云");

  Color _genStatusColor(ServerStatus status) {
    final _colors = <ServerStatus, Color> {
      ServerStatus.Normal: Vx.green600,
      ServerStatus.Warning: Vx.yellow600,
      ServerStatus.Error: Vx.red600,
    };
    return _colors[status] ?? _colors[ServerStatus.Warning];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return <Widget>[
            SliverOverlapAbsorber(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
              sliver: SliverAppBar(
                pinned: true,
                floating: true,
                expandedHeight: MediaQuery.of(context).size.height * 0.50,
                // title: Text("易付"),
                // centerTitle: true,
                title: VxBox(
                  child: [
                    VxBox().size(10, 10)
                      .color(_genStatusColor(currentServer.status))
                      .roundedFull.margin(Vx.mH8).make(),
                    "易付 • ${currentServer.name}".text.bold.gray900.maxFontSize(14).make(),
                    Icon(Icons.chevron_right, color: Vx.gray600),
                  ].hStack()
                ).white.withRounded(value: 100).p8.make()
                  .onInkTap(() {
                    ZBottomSheet(
                      ServerList().box.height(420).make(),
                      cancel: "取消".text.make(),
                      onCancel: () => true,
                      actions: [
                        ZButton(
                          child: "管理".text.make(),
                          onPressed: () => {
                            Navigator.of(context).popAndPushNamed("/servers")
                          },
                          primary: Colors.teal,
                        ).box.width(200).make(),
                      ],
                      isDismissible: true,
                    ).showModal(context);
                  }),
                actions: [
                    IconButton(icon: Icon(Icons.analytics), onPressed: () => Navigator.pushNamed(context, "/analytics")),
                    IconButton(icon: Icon(Icons.settings), onPressed: () => Navigator.pushNamed(context, "/settings"))
                ],
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.pin,
                  background: Fn.withBackground(
                    child: StatePanel(),
                    color: Colours.primaryColor2,
                    imageUrl: "assets/images/flat-mountains.png",
                    radiusArray: [0, 0, 20, 20],
                  ).box.color(Colors.white).make(),
                ),
              ),
            )
          ];
        },
        body: TransList().box.margin(Vx.mOnly(top: 84)).make(),
      ),
    );
  }
}