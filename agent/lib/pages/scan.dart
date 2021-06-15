

// scan to add config for server

import 'dart:convert';
import 'dart:io';

import 'package:agent/models/server.dart';
import 'package:agent/pages/server_profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_zoekits/flutter_zoekits.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:velocity_x/velocity_x.dart';

class ScanPage extends StatefulWidget {
  @override
  _ScanPageState createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'scan');
  Barcode result;
  QRViewController controller;

  @override
  void reassemble() {
    super.reassemble();
    Platform.isAndroid ? controller.pauseCamera() : controller.resumeCamera();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: <Widget>[
        _buildQrView(context).expand(flex: 4),
        [
          [
            IconButton(icon: Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.of(context).pop()),
          ].hStack(alignment: MainAxisAlignment.start, axisSize: MainAxisSize.max)
            .box.make(),
          [
            "请扫描服务端生成的注册二维码".text.white.bold.size(16).make(),
            ZButton(
              child: "手动填写内容".text.size(14).make(),
              type: ButtonType.Elevated, primary: Colors.teal,
              onPressed: () => {
                Navigator.of(context).pop(),
                Navigator.of(context).pushNamed(
                  "/server-profile",
                  arguments: ServerProfilePageArgs(createMode: true),
                )
              })
              .box.margin(Vx.mOnly(top: 48)).make()
          ].vStack().box.make(),
        ].vStack(
          alignment: MainAxisAlignment.spaceBetween,
          crossAlignment: CrossAxisAlignment.center,
          axisSize: MainAxisSize.max,
        ).centered().p12()
      ].zStack(),
    );
  }
  Widget _buildQrView(BuildContext context) {
    final size = MediaQuery.of(context).size;
    // For this example we check how width or tall the device is and change the scanArea and overlay accordingly.
    var scanArea = (size.width < 400 || size.height < 400) ? 150.0 : 300.0;
    // To ensure the Scanner view is properly sizes after rotation
    // we need to listen for Flutter SizeChanged notification and update controller
    return QRView(
      key: qrKey,
      // You can choose between CameraFacing.front or CameraFacing.back. Defaults to CameraFacing.back
      // cameraFacing: CameraFacing.front,
      onQRViewCreated: _onQRViewCreated,
      // Choose formats you want to scan. Defaults to all formats.
      // formatsAllowed: [BarcodeFormat.qrcode],
      overlay: QrScannerOverlayShape(
        borderColor: Theme.of(context).primaryColor,
        borderRadius: 10,
        borderLength: 30,
        borderWidth: 10,
        cutOutSize: scanArea,
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      this.controller = controller;
    });
    controller.scannedDataStream.listen((scanData) {
      // base64: peasy://{base64}
      // if result is not {} alert error.
      final data = scanData.code;

      if (!data.contains("://")) {
        return;
      }

      if (data.startsWith("http")) {
        // webview open the url
        return;
      }

      if (!data.startsWith("peasy")) {
        // others app???
        return;
      }

        // ook let's decode the data
      final str = base64Decode(data.split("://")[1]).toString();

      try {
        Map<String, dynamic> res = jsonDecode(str);
        // 检查校验
        var server = Server.fromMap(res);
        // 跳转到编辑页面
        Navigator.of(context)
        .pushNamed(
          "/server-profile",
          arguments: ServerProfilePageArgs(
            createMode: true,
            server: server,
          ),
        );
      } catch (e) {
        print("===> $e");
      }
    });
  }
}