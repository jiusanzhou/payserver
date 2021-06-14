// transaction list

import 'package:agent/models/transaction.dart';
import 'package:agent/styles/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_zoekits/flutter_zoekits.dart';
import 'package:provider/provider.dart';
import "package:velocity_x/velocity_x.dart";

class TransList extends StatefulWidget {
  @override
  _TransListState createState() => _TransListState();
}

class _TransListState extends State<TransList> {

  double logoSize = 35.0;

  PayTransactionModel _model;

  @override
  Widget build(BuildContext context) {
    return Consumer<PayTransactionModel>(
      builder: (context, model, child) {
        if (_model == null) _model = model;
        return [
          // VxBox(child: <Widget>[
          //   "方式".text.make().expand(flex: 1),
          //   "".text.make().expand(flex: 5),
          //   "状态".text.make().expand(flex: 1),
          // ].hStack()).width(double.infinity).height(50).border().white.make(),
          ListViewAsync(
            hasMore: () => model.hasMore,
            onLoadMore: model.loadMoreAllTrans,
            items: model.trans,
            itemRender: (BuildContext context, dynamic item, int index) {
              var _item = item as PayTransaction;
              // TextButton(onPressed: , child: child)
              return ListTile(
                // onTap: () => {},
                leading: ClipOval(
                  child: "assets/logos/${_item.type.text}.png".image(size: logoSize),
                ),
                title: "${_item.type.name}收款".text.make(),
                subtitle: _item.createAt.toString().split(".")[0].text.make(),
                // Icon(Icons.check, color: Colors.green),
                trailing: "+ ${_item.value}".text.color(Theme.of(context).primaryColor).size(18).bold.make()
              );
            },
            separator: VxBox().height(1).color(Colours.bgLight).make().px16(),
          ).expand(),
        ].vStack();
      });
  }
}