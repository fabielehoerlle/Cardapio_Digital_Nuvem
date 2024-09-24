import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Pedidos extends StatefulWidget {
  const Pedidos({Key? key}) : super(key: key);

  @override
  _PedidosState createState() => _PedidosState();
}

class _PedidosState extends State<Pedidos> {
  // columns in the dd_menu_pedidos table:
  // id, created_at, menu_category_id, menu_variation_id, menu_options
  final _pedidosFuture = Supabase.instance.client
      .from('dd_menu_pedidos')
      .select()
      .order('id', ascending: false);
  // columns in the dd_menu_categories table:
  // id, name, description, price, image
  final _categoriesFuture =
      Supabase.instance.client.from('dd_menu_categories').select();
  // columns in the dd_menu_variations table:
  // id, name, description, price, image
  final _variationsFuture =
      Supabase.instance.client.from('dd_menu_variations').select();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future:
          Future.wait([_pedidosFuture, _categoriesFuture, _variationsFuture]),
      builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final pedidos = snapshot.data![0] as List<dynamic>;
        final categories = {for (var c in snapshot.data![1]) c['id']: c};
        final variations = {for (var v in snapshot.data![2]) v['id']: v};

        return Column(children: [
          for (var pedido in pedidos) buildItem(pedido, categories, variations)
        ]);
      },
    );
  }

  Widget buildItem(dynamic pedido, Map<dynamic, dynamic> categories,
      Map<dynamic, dynamic> variations) {
    final String categoryName = categories[pedido['menu_category_id']]['name'];
    final String variationName =
        variations[pedido['menu_variation_id']]['name'];
    final Map<String, dynamic> options = jsonDecode(pedido['menu_options']);
    final optionsKeys = options.keys;
    return Container(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$categoryName - $variationName",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          for (var ok in optionsKeys)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("$ok",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 12)),
                Text("${options[ok]}", style: const TextStyle(fontSize: 12)),
              ],
            ),
        ],
      ),
    );
  }
}
