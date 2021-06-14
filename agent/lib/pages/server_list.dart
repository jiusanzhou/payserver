

// payserver servers list

import 'package:agent/views/server_list.dart';
import 'package:flutter/material.dart';
import 'package:velocity_x/velocity_x.dart';

class ServerListPage extends StatefulWidget {
  @override
  _ServerListPageState createState() => _ServerListPageState();
}

class _ServerListPageState extends State<ServerListPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: "服务列表".text.make(),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () => Navigator.of(context).pushNamed("/scan"),
          )
        ],
      ),
      body: ServerList(viewMode: false),
    );
  }
}