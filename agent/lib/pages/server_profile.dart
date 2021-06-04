

import 'package:agent/models/server.dart';
import 'package:flutter/material.dart';

class ServerProfilePage extends StatefulWidget {

  final Server server;
  final Map<String, dynamic> data;

  ServerProfilePage({this.server, this.data});

  @override
  _ServerProfilePageState createState() => _ServerProfilePageState();
}

class _ServerProfilePageState extends State<ServerProfilePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        
      ),
    );
  }
}