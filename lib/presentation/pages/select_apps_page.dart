import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:pug_vpn/core/providers.dart';
import 'package:pug_vpn/domain/entities/device_app.dart';
import 'package:pug_vpn/domain/repositories/native_vpn_repository.dart';
import 'package:pug_vpn/presentation/localization/app_strings.dart';
import 'package:pug_vpn/presentation/theme/app_theme.dart';
import 'package:pug_vpn/presentation/viewmodels/app_selection_viewmodel.dart';
import 'package:pug_vpn/presentation/viewmodels/tab_viewmodel.dart';

class SelectAppsPage extends StatefulWidget {
  const SelectAppsPage({super.key});

  @override
  State<SelectAppsPage> createState() => _SelectAppsPageState();
}

class _SelectAppsPageState extends State<SelectAppsPage> {
  late final NativeVpnRepository _nativeVpn;
  final Set<String> _draftSelection = <String>{};
  bool _initializedDraft = false;

  @override
  void initState() {
    super.initState();
    _nativeVpn = createNativeVpnRepository();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppSelectionViewModel>().ensureLoaded();
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final vm = context.watch<AppSelectionViewModel>();
    final strings = AppStrings.of(context);

    if (vm.isLoaded && !_initializedDraft) {
      _draftSelection
        ..clear()
        ..addAll(vm.selectedPackages);
      _initializedDraft = true;
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: <Widget>[
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.4),
                radius: 1.2,
                colors: palette.backgroundGradient,
                stops: const <double>[0.0, 0.6, 1.0],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: <Widget>[
                  const SizedBox(height: 18),
                  Row(
                    children: <Widget>[
                      InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.chevron_left_rounded,
                            color: palette.secondaryText,
                            size: 28,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        strings.selectAppsTitle,
                        style: TextStyle(
                          color: palette.primaryText,
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 4, top: 6, right: 4),
                    child: Text(
                      strings.onlySelectedApps,
                      style: TextStyle(
                        color: palette.secondaryText,
                        fontSize: 14,
                        height: 1.45,
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _SelectionActions(
                    palette: palette,
                    selectedCount: _draftSelection.length,
                    totalCount: vm.apps.length,
                    strings: strings,
                    onSelectAll: () {
                      setState(() {
                        _draftSelection
                          ..clear()
                          ..addAll(vm.allPackages);
                      });
                    },
                    onReset: () {
                      setState(() {
                        _draftSelection
                          ..clear()
                          ..addAll(vm.allPackages);
                      });
                    },
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: Builder(
                      builder: (BuildContext context) {
                        if (vm.isLoading && vm.apps.isEmpty) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (vm.apps.isEmpty) {
                          return Center(
                            child: Text(
                              vm.errorMessage ?? strings.noAppsFound,
                              style: TextStyle(
                                color: palette.secondaryText,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          );
                        }

                        return ListView.separated(
                          padding: const EdgeInsets.only(bottom: 12),
                          itemCount: vm.apps.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (BuildContext context, int index) {
                            final app = vm.apps[index];
                            return _SelectAppTile(
                              app: app,
                              palette: palette,
                              selected: _draftSelection.contains(app.packageName),
                              onChanged: (bool value) {
                                setState(() {
                                  if (value) {
                                    _draftSelection.add(app.packageName);
                                  } else {
                                    _draftSelection.remove(app.packageName);
                                  }
                                });
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SaveButton(
                    palette: palette,
                    label: strings.save,
                    onTap: vm.apps.isEmpty
                        ? null
                        : () => _saveSelection(context),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveSelection(BuildContext context) async {
    final selectionVm = context.read<AppSelectionViewModel>();
    final tabVm = context.read<TabViewModel>();
    final previousSelection = selectionVm.selectedPackages;
    final hasChanged = !_sameSelection(previousSelection, _draftSelection);

    await selectionVm.saveSelection(_draftSelection);

    if (hasChanged) {
      if (tabVm.isConnected) {
        await _nativeVpn.disconnect();
      }
      if (!mounted) return;
      tabVm.setConnection(
        isConnected: false,
        location: 'RU',
        details: 'Russia',
      );
      tabVm.changeTab(0);
    }

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  bool _sameSelection(Set<String> left, Set<String> right) {
    if (left.length != right.length) return false;
    return left.containsAll(right);
  }
}

class _SelectionActions extends StatelessWidget {
  const _SelectionActions({
    required this.palette,
    required this.selectedCount,
    required this.totalCount,
    required this.strings,
    required this.onSelectAll,
    required this.onReset,
  });

  final AppPalette palette;
  final int selectedCount;
  final int totalCount;
  final AppStrings strings;
  final VoidCallback onSelectAll;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Expanded(
          child: Text(
            '${strings.selected} $selectedCount / $totalCount',
            style: TextStyle(
              color: palette.secondaryText,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _ActionChip(
              label: strings.selectAll,
              palette: palette,
              onTap: onSelectAll,
            ),
            const SizedBox(width: 8),
            _ActionChip(
              label: strings.reset,
              palette: palette,
              onTap: onReset,
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.label,
    required this.palette,
    required this.onTap,
  });

  final String label;
  final AppPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: palette.softFill,
          border: Border.all(color: palette.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: palette.primaryText,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _SelectAppTile extends StatelessWidget {
  const _SelectAppTile({
    required this.app,
    required this.palette,
    required this.selected,
    required this.onChanged,
  });

  final DeviceApp app;
  final AppPalette palette;
  final bool selected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: selected
                  ? <Color>[
                      palette.cardGradient.first.withValues(alpha: 0.98),
                      palette.cardGradient.last,
                    ]
                  : palette.cardGradient,
            ),
            border: Border.all(color: palette.border),
          ),
          child: Row(
            children: <Widget>[
              _AppIcon(app: app, palette: palette),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      app.label,
                      style: TextStyle(
                        color: palette.primaryText,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      app.packageName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: palette.secondaryText,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Checkbox(
                value: selected,
                onChanged: (bool? value) => onChanged(value ?? false),
                activeColor: const Color(0xFF7B93D8),
                checkColor: Colors.white,
                side: BorderSide(color: palette.secondaryText),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppIcon extends StatelessWidget {
  const _AppIcon({
    required this.app,
    required this.palette,
  });

  final DeviceApp app;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: palette.softFill,
      ),
      clipBehavior: Clip.antiAlias,
      child: app.iconBytes != null
          ? Image.memory(
              app.iconBytes!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _AppIconFallback(
                label: app.label,
                palette: palette,
              ),
            )
          : _AppIconFallback(
              label: app.label,
              palette: palette,
            ),
    );
  }
}

class _AppIconFallback extends StatelessWidget {
  const _AppIconFallback({
    required this.label,
    required this.palette,
  });

  final String label;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        label.isEmpty ? '?' : label.substring(0, 1).toUpperCase(),
        style: TextStyle(
          color: palette.primaryText,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  const _SaveButton({
    required this.palette,
    required this.label,
    required this.onTap,
  });

  final AppPalette palette;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: onTap == null
                ? const <Color>[Color(0xFF9AA6BD), Color(0xFF8794AD)]
                : const <Color>[Color(0xFF7D96D9), Color(0xFF5878C8)],
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  color: palette.isDark ? Colors.white : const Color(0xFFF8FBFF),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
