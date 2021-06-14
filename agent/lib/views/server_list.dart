

import 'package:agent/models/models.dart';
import 'package:agent/models/server.dart';
import 'package:agent/models/transaction.dart';
import 'package:agent/pages/server_profile.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_zoekits/flutter_zoekits.dart';
import 'package:provider/provider.dart';
import 'package:velocity_x/velocity_x.dart';

class ServerList extends StatefulWidget {

  final bool viewMode;

  @override
  _ServerListState createState() => _ServerListState();

  ServerList({
    this.viewMode = true,
  });
}

// choose current server
var _colors = [
  Color(0xff788aa9), Color(0xfff6bd16),
  Color(0xff5ad8a6), Color(0xff6dc8ec),
  Color(0xff7ca5fa), Color(0xff074bd5),
];

class _ServerListState extends State<ServerList> {

  double logoSize = 16;

  ServerModel _model;

  void _onTapSelect(Server server) {
    VxDialog.showConfirmation(
      context,
      title: "确认切换服务?",
      content: "切换服务会重新运行程序，并且可能出现期间的数据丢失。",
      confirm: "确认",
      onConfirmPress: () {
        ModelFactory.instance.servr.setCurrentServer(server);
        // Navigator.of(context).pop();
      },
      cancel: "取消".text.make(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ServerModel>(
      builder: (context, model, child) {
        if (_model == null) _model = model;
        return ListViewBasic(
          items: model.servers,
          itemRender: (context, item, index) {
            Server server = item as Server;
            bool checked = model.currentServer.id == server.id;
            return VxBox(
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(100)),
                ),
                onTap: () {
                  if (widget.viewMode) {
                    if (!checked) _onTapSelect(server);
                  } else {
                   // push to edit
                   Navigator.of(context)
                    .pushNamed(
                      "/server-profile",
                      arguments: ServerProfilePageArgs(
                        createMode: false,
                        server: server,
                      ),
                    );
                  }
                },
                leading: Icon(Icons.public, color: Colors.white)
                  .box.width(48).height(48).color(_colors[index % _colors.length]).p4.roundedFull.make(),
                title: [
                  server.name.text.bold.make(),
                  server.types.map((e) => Image.asset("assets/logos/${e.text}.png", width: logoSize, height: logoSize, fit: BoxFit.cover,).p4()).toList().hStack()
                ].hStack(alignment: MainAxisAlignment.spaceBetween, axisSize: MainAxisSize.max),
                subtitle: "${server.host??""}".text.make(),
                trailing: Icon(
                  checked ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                  color: checked ? Theme.of(context).primaryColor : null,
                ).onTap(() {
                  if (!checked) _onTapSelect(server);
                }),
              ).box.withRounded(value: 100).color(checked ? Theme.of(context).primaryColor.withAlpha(25) : null).make()
                
            ).p8.make();
          },
        );
      }
    );
  }
}