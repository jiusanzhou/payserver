


import 'package:agent/models/server.dart';
import 'package:agent/models/transaction.dart';
import 'package:agent/styles/colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_zoekits/flutter_zoekits.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:velocity_x/velocity_x.dart';

class ServerProfilePage extends StatefulWidget {

  final Server server;
  final Map<String, dynamic> data;

  ServerProfilePage({this.server, this.data});

  @override
  _ServerProfilePageState createState() => _ServerProfilePageState();
}

class _ServerProfilePageState extends State<ServerProfilePage> {

  Server server;
  bool createMode = true;

  bool get _editable => server?.id != -1;

  ServerModel _model;

  @override
  void initState() {
    super.initState();

    SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
      final ServerProfilePageArgs args = ModalRoute.of(context).settings.arguments;
      setState(() {
        server = args.server ?? Server.empty();
        createMode = args.createMode ?? true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: "${createMode?"新增":"编辑"}服务".text.make(),
        centerTitle: true,
        actions: [
          Consumer<ServerModel>(
            builder: (context, model, child) {
              if (_model == null) _model = model;
              return ZButton(
                  primary: Colors.white,
                  type: ButtonType.Text,
                  child: "保存".text.make(),
                  onPressed: () {
                    print("===> $server");
                    if (createMode) {
                      _model.insertServer(server);
                      VxToast.show(context, msg: "新增成功");
                      Navigator.of(context).pop();
                    } else {
                      _model.updateServer(server);
                      VxToast.show(context, msg: "更新成功");
                    }
                  },
                );
            },
          ),
        ],
      ),
      backgroundColor: Colours.bgLight,
      body: server==null?Container():SingleChildScrollView(
        child: [
          [
            [
              Menu(
                title: "服务名称",
                icon: Icons.public,
                value: server?.name,
                opts: InputFieldOptions(
                  onChanged: (v) => server.name = v,
                  editable: _editable,
                )
              ),
              Menu(
                title: "服务地址",
                icon: Icons.location_city,
                value: server?.host,
                opts: InputFieldOptions(
                  onChanged: (v) => server.host = v,
                  editable: _editable,
                )
              ),
              Menu(
                title: "注册密钥",
                icon: Icons.security,
                value: server?.ticket,
                opts: InputFieldOptions(
                  onChanged: (v) => server.ticket = v,
                )
              ),
            ].blockGroup(Menu(
              title: "基本信息",
              separated: true,
              background: Colors.white
            ), separated: true),

            // auto load package from installed apps list
            [
              Menu(
                title: "微信",
                leading: ZLogo(src: "assets/logos/wechat.png", size: 32),
                value: server?.types?.contains(PayType.WeChat) ?? false,
                opts: InputFieldOptions(
                  onChanged: (v) {
                    if (v) {
                      // add
                      if (!(server?.types?.contains(PayType.WeChat) ?? false))
                        server?.types?.add(PayType.WeChat);
                    } else {
                      // remove
                      server?.types?.remove(PayType.WeChat);
                    }
                  }
                )
              ),
              Menu(
                title: "支付宝",
                leading: ZLogo(src: "assets/logos/alipay.png", size: 32),
                value: server?.types?.contains(PayType.Alipay) ?? false,
                opts: InputFieldOptions(
                  onChanged: (v) {
                    if (v) {
                      // add
                      if (!(server?.types?.contains(PayType.Alipay) ?? false))
                        server?.types?.add(PayType.Alipay);
                    } else {
                      // remove
                      server?.types?.remove(PayType.Alipay);
                    }
                  }
                )
              ),
            ].blockGroup(Menu(
              title: "支付方式",
              description: "请确保手机上已登录相应的收款帐号。",
              separated: true,
              background: Colors.white
            ), separated: true),

            [
              Menu(
                title: "分享二维码",
                icon: Icons.qr_code,
                expended: true,
                onTap: () {
                  ZBottomSheet(
                    [
                      "其他设备可以扫描此二维码进行注册".text.semiBold.make(),
                      QrImage(
                        data: "base64 json encoded",
                        size: 200,
                      ).box.p20.make()
                    ].vStack(),
                    cancel: "取消".text.make(),
                    onCancel: () {
                      return true;
                    },
                  ).showModal(context);
                }
              ),
              Menu(
                title: "复制JSON",
                icon: Icons.code,
                expended: true,
                onTap: () {
                  Clipboard.setData(ClipboardData(
                    text: "", // json.encode((args.server as Server).toMap())
                  )).then((value) {
                    VxToast.show(context, msg: "已复制 JSON");
                  });
                }
              )
            ].blockGroup(Menu(
              title: "其他",
              background: Colors.white,
            ), separated: true)

          ].make(separator: VxBox().height(10).make(), separated: true),
          VxBox().height(20).make(),
          ZButton(
            child: "删除".text.make(),
            primary: Colors.red,
            onPressed: server.id == -1
              || server.id == _model.currentServer.id
              ? null
              : () {
                _model.deleteServer(server);
                VxToast.show(context, msg: "服务删除成功");
                Navigator.of(context).pop();
            },
          ).box.width(280).height(48).px20.make(),
          VxBox().height(200).make(),
        ].vStack()
      ),
    );
  }
}

class ServerProfilePageArgs {
  bool createMode;
  Server server;

  ServerProfilePageArgs({
    this.createMode = true,
    this.server,
  });
}