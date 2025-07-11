import 'package:flutter/material.dart';
import 'package:getwidget/components/tabs/gf_segment_tabs.dart';

class DetailViewSwitcher extends StatefulWidget {
  final int initialIndex;
  final ValueChanged<int> onTap;
  final Color activeColor;

  const DetailViewSwitcher({
    super.key,
    required this.initialIndex,
    required this.onTap,
    required this.activeColor,
  });

  @override
  DetailViewSwitcherState createState() => DetailViewSwitcherState();
}

class DetailViewSwitcherState extends State<DetailViewSwitcher>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialIndex,
    );
    // Añadimos el listener para llamar a la función del controlador
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        widget.onTap(_tabController.index);
      }
    });
  }

  @override
  void didUpdateWidget(covariant DetailViewSwitcher oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si el índice cambia desde fuera (ej, al cambiar de proyecto), actualizamos el tab
    if (widget.initialIndex != _tabController.index) {
      _tabController.animateTo(widget.initialIndex);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final icons = [
      Icons.bar_chart,
      Icons.history_toggle_off,
      Icons.people_outline,
      Icons.vpn_key_outlined,
    ];
    final labels = ['Resumen', 'Actividad', 'Miembros', 'Acceso'];

    // --- CÓDIGO CORREGIDO DE GFSegmentTabs ---
    return GFSegmentTabs(
      tabController: _tabController,
      length: 4, // <-- Parámetro 'length' añadido
      height: 50,
      width: 600,
      tabs: <Widget>[
        for (int i = 0; i < 4; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icons[i], color: Colors.white),
                const SizedBox(width: 8),
                Text(labels[i], style: const TextStyle(color: Colors.white)),
              ],
            ),
          ),
      ],
      border: Border.all(color: Colors.white30),
      tabBarColor: Colors.transparent, // Usa 'tabBarColor' en lugar de 'color'
      indicatorColor: widget.activeColor,
    );
  }
}
