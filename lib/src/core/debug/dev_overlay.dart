import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:sistema_vacunacion/src/config/config.dart';
import 'package:sistema_vacunacion/src/core/debug/dev_log_service.dart';
import 'package:sistema_vacunacion/src/presentation/state/services.dart';

class DevOverlay extends StatefulWidget {
  final Widget child;
  const DevOverlay({super.key, required this.child});

  @override
  State<DevOverlay> createState() => _DevOverlayState();
}

class _DevOverlayState extends State<DevOverlay> {
  bool _panelVisible = false;
  Offset _buttonOffset = const Offset(8, 160);
  bool _dragging = false;

  void _togglePanel() {
    if (_dragging) return;
    setState(() => _panelVisible = !_panelVisible);
  }

  void _cerrar() => setState(() => _panelVisible = false);

  @override
  Widget build(BuildContext context) {
    const dur = Duration(milliseconds: 260);

    return Stack(
      children: [
        widget.child,

        // fondo semitransparente
        IgnorePointer(
          ignoring: !_panelVisible,
          child: AnimatedOpacity(
            opacity: _panelVisible ? 1.0 : 0.0,
            duration: dur,
            child: GestureDetector(
              onTap: _cerrar,
              behavior: HitTestBehavior.opaque,
              child: Container(color: Colors.black45),
            ),
          ),
        ),

        // panel
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: IgnorePointer(
            ignoring: !_panelVisible,
            child: AnimatedSlide(
              offset: _panelVisible ? Offset.zero : const Offset(0, 1),
              duration: dur,
              curve: Curves.easeOutCubic,
              child: AnimatedOpacity(
                opacity: _panelVisible ? 1.0 : 0.0,
                duration: dur,
                child: Material(
                  elevation: 16,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                  child: SafeArea(
                    top: false,
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height * 0.78,
                      child: _DevPanel(onCerrar: _cerrar),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        // botón flotante arrastrable
        Positioned(
          right: _buttonOffset.dx,
          top: _buttonOffset.dy,
          child: GestureDetector(
            onPanStart: (_) => setState(() => _dragging = true),
            onPanUpdate: (d) {
              setState(() {
                final size = MediaQuery.of(context).size;
                _buttonOffset = Offset(
                  (_buttonOffset.dx - d.delta.dx).clamp(0.0, size.width - 48),
                  (_buttonOffset.dy + d.delta.dy).clamp(40.0, size.height - 80),
                );
              });
            },
            onPanEnd: (_) =>
                Future.microtask(() => setState(() => _dragging = false)),
            onTap: _togglePanel,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _panelVisible
                    ? Colors.deepPurple
                    : Colors.deepPurple.withAlpha(200),
                shape: BoxShape.circle,
                boxShadow: const [
                  BoxShadow(
                      color: Colors.black38,
                      blurRadius: 4,
                      offset: Offset(2, 2)),
                ],
              ),
              child: Icon(
                _panelVisible ? Icons.close : Icons.bug_report,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Panel principal
// ─────────────────────────────────────────────────────────────────────────────

class _DevPanel extends StatelessWidget {
  final VoidCallback onCerrar;
  const _DevPanel({required this.onCerrar});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.bug_report,
                    color: Colors.deepPurple, size: 16),
                const SizedBox(width: 8),
                Text(
                  'DEV Panel',
                  style: context.sisTipografia.textoPrincipal.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: onCerrar,
                  child: const Icon(Icons.close, size: 20),
                ),
              ],
            ),
          ),
          TabBar(
            labelStyle: context.sisTipografia.textoChip.copyWith(
              fontWeight: FontWeight.w400,
            ),
            tabs: const [
              Tab(text: 'Sesión'),
              Tab(text: 'API Logs'),
              Tab(text: 'Registro JSON'),
            ],
          ),
          const Expanded(
            child: TabBarView(
              children: [
                _TabSesion(),
                _TabApiLogs(),
                _TabRegistroJson(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 1 – Sesión
// ─────────────────────────────────────────────────────────────────────────────

class _TabSesion extends StatefulWidget {
  const _TabSesion();
  @override
  State<_TabSesion> createState() => _TabSesionState();
}

class _TabSesionState extends State<_TabSesion> {
  late final List<VoidCallback> _detenerListeners;

  @override
  void initState() {
    super.initState();
    void rebuild() => setState(() {});
    beneficiarioService.beneficiarioEstado.addListener(rebuild);
    tutorService.tutorEstado.addListener(rebuild);
    registradorService.registradorEstado.addListener(rebuild);
    vacunadorService.vacunadorEstado.addListener(rebuild);
    efectoresService.efectoresEstado.addListener(rebuild);
    _detenerListeners = [
      () => beneficiarioService.beneficiarioEstado.removeListener(rebuild),
      () => tutorService.tutorEstado.removeListener(rebuild),
      () => registradorService.registradorEstado.removeListener(rebuild),
      () => vacunadorService.vacunadorEstado.removeListener(rebuild),
      () => efectoresService.efectoresEstado.removeListener(rebuild),
    ];
  }

  @override
  void dispose() {
    for (final detener in _detenerListeners) {
      detener();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final b = beneficiarioService.beneficiario;
    final v = vacunadorService.vacunador;
    final r = registradorService.registrador;
    final t = tutorService.tutor;
    final e = efectoresService.efectores;

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _Seccion(
          titulo: 'Beneficiario',
          icono: Icons.person,
          filas: b == null
              ? [const _Fila('Estado', '—— sin cargar ——')]
              : [
                  _Fila('DNI', b.sysdesa10_dni ?? '-'),
                  _Fila('Nombre',
                      '${b.sysdesa10_apellido ?? ''}, ${b.sysdesa10_nombre ?? ''}'),
                  _Fila('Sexo', b.sysdesa10_sexo ?? '-'),
                  _Fila('Edad', b.sysdesa10_edad ?? '-'),
                  _Fila('F. nac.', b.sysdesa10_fecha_nacimiento ?? '-'),
                  _Fila(
                      'Foto',
                      b.foto_beneficiario != null
                          ? '${b.foto_beneficiario!.length} chars'
                          : 'sin foto'),
                  _Fila('codigo_msg', b.codigo_mensaje ?? '-'),
                ],
        ),
        const SizedBox(height: 8),
        _Seccion(
          titulo: 'Vacunador',
          icono: Icons.medical_services,
          filas: v == null
              ? [const _Fila('Estado', '—— sin cargar ——')]
              : [
                  _Fila('DNI', v.sysdesa06_nro_documento ?? '-'),
                  _Fila('Nombre', v.sysdesa06_nombre ?? '-'),
                  _Fila('id_sysdesa12', v.id_sysdesa12 ?? '-'),
                  _Fila('codigo_msg', v.codigo_mensaje ?? '-'),
                ],
        ),
        const SizedBox(height: 8),
        _Seccion(
          titulo: 'Registrador',
          icono: Icons.badge,
          filas: r == null
              ? [const _Fila('Estado', '—— sin cargar ——')]
              : [
                  _Fila('DNI', r.flxcore03_dni ?? '-'),
                  _Fila('Nombre', r.flxcore03_nombre ?? '-'),
                  _Fila('id_flxcore03', r.id_flxcore03 ?? '-'),
                  _Fila('Efector', r.sysofic01_descripcion ?? '-'),
                  _Fila('id_sysofic01', r.rela_sysofic01 ?? '-'),
                ],
        ),
        const SizedBox(height: 8),
        _Seccion(
          titulo: 'Tutor',
          icono: Icons.family_restroom,
          filas: !tutorService.existeTutor
              ? [const _Fila('Estado', '—— sin tutor ——')]
              : [
                  _Fila('DNI tutor', t!.sysdesa10_dni_tutor ?? '-'),
                  _Fila(
                      'Nombre',
                      '${t.sysdesa10_apellido_tutor ?? ''}, ${t.sysdesa10_nombre_tutor ?? ''}'),
                  _Fila('Sexo', t.sysdesa10_sexo_tutor ?? '-'),
                ],
        ),
        const SizedBox(height: 8),
        _Seccion(
          titulo: 'Efector seleccionado',
          icono: Icons.local_hospital,
          filas: e == null
              ? [const _Fila('Estado', '—— sin seleccionar ——')]
              : [
                  _Fila('Descripción', e.sysofic01Descripcion ?? '-'),
                  _Fila('id_sysofic01', e.relaSysofic01 ?? '-'),
                ],
        ),
        const SizedBox(height: 8),
        _Seccion(
          titulo: 'Sesión equipo',
          icono: Icons.settings,
          filas: [
            _Fila('En terreno',
                sesionEquipoVacunacionService.enTerreno ? 'Sí' : 'No'),
          ],
        ),
      ],
    );
  }
}

class _Seccion extends StatelessWidget {
  final String titulo;
  final IconData icono;
  final List<Widget> filas;
  const _Seccion(
      {required this.titulo, required this.icono, required this.filas});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icono, size: 14, color: Colors.deepPurple),
                const SizedBox(width: 6),
                Text(
                  titulo,
                  style: context.sisTipografia.textoChip.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 10),
            ...filas,
          ],
        ),
      ),
    );
  }
}

class _Fila extends StatelessWidget {
  final String etiqueta;
  final String valor;
  const _Fila(this.etiqueta, this.valor);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              etiqueta,
              style: context.sisTipografia.etiquetaSeccion.copyWith(
                letterSpacing: 0,
                fontWeight: FontWeight.w400,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              valor,
              style: context.sisTipografia.etiquetaSeccion.copyWith(
                letterSpacing: 0,
                fontWeight: FontWeight.w400,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 2 – API Logs
// ─────────────────────────────────────────────────────────────────────────────

class _TabApiLogs extends StatelessWidget {
  const _TabApiLogs();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<DevLogEntry>>(
      stream: devLogService.logsStream,
      initialData: devLogService.logs,
      builder: (context, snap) {
        final logs = snap.data ?? [];
        return Column(
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                children: [
                  Text(
                    '${logs.length} entradas',
                    style: context.sisTipografia.etiquetaSeccion.copyWith(
                      letterSpacing: 0,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: devLogService.limpiar,
                    child: Text(
                      'Limpiar',
                      style: context.sisTipografia.etiquetaSeccion.copyWith(
                        letterSpacing: 0,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: logs.isEmpty
                  ? Center(
                      child: Text(
                        'Sin logs aún.',
                        style: context.sisTipografia.textoSecundario.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8),
                      itemCount: logs.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, thickness: 0.5),
                      itemBuilder: (_, i) => _LogTile(entry: logs[i]),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _LogTile extends StatelessWidget {
  final DevLogEntry entry;
  const _LogTile({required this.entry});

  static const _colores = {
    DevLogTipo.apiRequest: Colors.blue,
    DevLogTipo.apiResponse: Colors.green,
    DevLogTipo.apiError: Colors.red,
    DevLogTipo.estadoCambiado: Colors.orange,
    DevLogTipo.info: Colors.grey,
  };

  static const _iconos = {
    DevLogTipo.apiRequest: Icons.upload,
    DevLogTipo.apiResponse: Icons.download,
    DevLogTipo.apiError: Icons.error_outline,
    DevLogTipo.estadoCambiado: Icons.change_circle_outlined,
    DevLogTipo.info: Icons.info_outline,
  };

  @override
  Widget build(BuildContext context) {
    final bar = context.sisTipografia;
    final color = _colores[entry.tipo] ?? Colors.grey;
    final icono = _iconos[entry.tipo] ?? Icons.info_outline;
    final hora =
        '${entry.timestamp.hour.toString().padLeft(2, '0')}:${entry.timestamp.minute.toString().padLeft(2, '0')}:${entry.timestamp.second.toString().padLeft(2, '0')}';

    return ExpansionTile(
      leading: Icon(icono, color: color, size: 16),
      tilePadding: const EdgeInsets.symmetric(horizontal: 4),
      childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      title: Text(
        '[${entry.tag}] ${entry.mensaje}',
        style: bar.etiquetaSeccion.copyWith(
          letterSpacing: 0,
          fontWeight: FontWeight.w400,
          color: color,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        hora,
        style: bar.etiquetaSeccion.copyWith(
          letterSpacing: 0,
          fontWeight: FontWeight.w400,
          color: Colors.grey,
        ),
      ),
      children: entry.datos == null
          ? const []
          : [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: SelectableText(
                  const JsonEncoder.withIndent('  ').convert(entry.datos),
                  style: bar.etiquetaSeccion.copyWith(
                    letterSpacing: 0,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 3 – Registro JSON
// ─────────────────────────────────────────────────────────────────────────────

class _TabRegistroJson extends StatefulWidget {
  const _TabRegistroJson();
  @override
  State<_TabRegistroJson> createState() => _TabRegistroJsonState();
}

class _TabRegistroJsonState extends State<_TabRegistroJson> {
  void _rebuild() => setState(() {});

  @override
  void initState() {
    super.initState();
    insertRegistroService.registroEstado.addListener(_rebuild);
  }

  @override
  void dispose() {
    insertRegistroService.registroEstado.removeListener(_rebuild);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bar = context.sisTipografia;
    final reg = insertRegistroService.registro;
    if (reg == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Sin registro en memoria.\nCompletar el formulario de vacunas para verlo aquí.',
            textAlign: TextAlign.center,
            style: bar.textoPrincipal.copyWith(color: Colors.grey),
          ),
        ),
      );
    }

    final jsonCompleto = reg.toJson();
    final jsonVista = Map<String, dynamic>.from(jsonCompleto);
    final cadena = jsonVista['sysdesa10_cadena_dni'];
    if (cadena != null && cadena.toString().length > 60) {
      jsonVista['sysdesa10_cadena_dni'] =
          '${cadena.toString().substring(0, 60)}… [${cadena.toString().length} chars]';
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            children: [
              Text(
                'Payload actual',
                style: bar.textoChip.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.copy, size: 18),
                tooltip: 'Copiar JSON completo',
                onPressed: () {
                  Clipboard.setData(ClipboardData(
                      text: const JsonEncoder.withIndent('  ')
                          .convert(jsonCompleto)));
                  ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                    const SnackBar(
                      content: Text('JSON copiado al portapapeles'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                const JsonEncoder.withIndent('  ').convert(jsonVista),
                style: bar.etiquetaSeccion.copyWith(
                  letterSpacing: 0,
                  fontWeight: FontWeight.w400,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

