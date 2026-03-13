import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:pug_vpn/domain/entities/device_app.dart';
import 'package:pug_vpn/presentation/theme/app_theme.dart';
import 'package:pug_vpn/presentation/viewmodels/app_selection_viewmodel.dart';

class SelectAppsPage extends StatefulWidget {
  const SelectAppsPage({super.key});

  @override
  State<SelectAppsPage> createState() => _SelectAppsPageState();
}

class _SelectAppsPageState extends State<SelectAppsPage> {
  final Set<String> _draftSelection = <String>{};
  bool _initializedDraft = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppSelectionViewModel>().ensureLoaded();
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final vm = context.watch<AppSelectionViewModel>();

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
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(
                          Icons.chevron_left_rounded,
                          color: palette.secondaryText,
                          size: 28,
                        ),
                      ),
                      Text(
                        'Select Apps',
                        style: TextStyle(
                          color: palette.primaryText,
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      'Only the selected apps will use the VPN. By default, all installed apps are selected.',
                      style: TextStyle(
                        color: palette.secondaryText,
                        fontSize: 14,
                        height: 1.45,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _SelectionActions(
                    palette: palette,
                    selectedCount: _draftSelection.length,
                    totalCount: vm.apps.length,
                    onSelectAll: () {
                      setState(() {
                        _draftSelection
                          ..clear()
                          ..addAll(vm.allPackages);
                      });
                    },
                    onReset: () {
                      setState(_draftSelection.clear);
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
                              vm.errorMessage ?? 'No launchable apps found on this device.',
                              style: TextStyle(
                                color: palette.secondaryText,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          );
                        }

                        return ListView.separated(
                          padding: const EdgeInsets.only(bottom: 20),
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
                  _SaveButton(
                    palette: palette,
                    onTap: vm.apps.isEmpty
                        ? null
                        : () {
                            context.read<AppSelectionViewModel>().saveSelection(
                              _draftSelection,
                            );
                            Navigator.of(context).pop();
                          },
                  ),
                  const SizedBox(height: 112),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectionActions extends StatelessWidget {
  const _SelectionActions({
    required this.palette,
    required this.selectedCount,
    required this.totalCount,
    required this.onSelectAll,
    required this.onReset,
  });

  final AppPalette palette;
  final int selectedCount;
  final int totalCount;
  final VoidCallback onSelectAll;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            'Selected $selectedCount of $totalCount',
            style: TextStyle(
              color: palette.secondaryText,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        _ActionChip(
          label: 'Select all',
          palette: palette,
          onTap: onSelectAll,
        ),
        const SizedBox(width: 8),
        _ActionChip(
          label: 'Reset',
          palette: palette,
          onTap: onReset,
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
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: palette.cardGradient,
            ),
            border: Border.all(color: palette.border),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(11),
                  color: palette.softFill,
                ),
                alignment: Alignment.center,
                child: Text(
                  app.label.isEmpty ? '?' : app.label.substring(0, 1).toUpperCase(),
                  style: TextStyle(
                    color: palette.primaryText,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      app.label,
                      style: TextStyle(
                        color: palette.primaryText,
                        fontSize: 16,
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  const _SaveButton({
    required this.palette,
    required this.onTap,
  });

  final AppPalette palette;
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
                'Save',
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
