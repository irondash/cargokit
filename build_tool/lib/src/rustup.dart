import 'dart:io';

import 'package:path/path.dart' as path;

import 'util.dart';

class _Toolchain {
  _Toolchain(
    this.name,
    this.targets,
  );

  final String name;
  final List<String> targets;
}

class Rustup {
  List<String> get installedToolchains =>
      _installedToolchains.map((e) => e.name).toList(growable: false);

  List<String> installedTargets(String toolchain) =>
      List.unmodifiable(_installedTargets(toolchain));

  void installToolchain(String toolchain) {
    log.info("Installing Rust toolchain: $toolchain");
    runCommand("rustup", ['toolchain', 'install', toolchain]);
    _installedToolchains
        .add(_Toolchain(toolchain, _getInstalledTargets(toolchain)));
  }

  void installTarget(
    String target, {
    required String toolchain,
  }) {
    log.info("Installing Rust target: $target");
    runCommand("rustup", [
      'target',
      'add',
      '--toolchain',
      toolchain,
      target,
    ]);
    _installedTargets(toolchain).add(target);
  }

  final List<_Toolchain> _installedToolchains;

  Rustup() : _installedToolchains = _getInstalledToolchains();

  List<String> _installedTargets(String toolchain) =>
      _installedToolchains.firstWhere((e) => e.name == toolchain).targets;

  static List<_Toolchain> _getInstalledToolchains() {
    final res = runCommand("rustup", ['toolchain', 'list']);
    final lines = res.stdout
        .toString()
        .split('\n')
        .where((e) => e.isNotEmpty)
        .toList(growable: true);
    return lines
        .map(
          (toolchain) => _Toolchain(
            toolchain,
            _getInstalledTargets(toolchain),
          ),
        )
        .toList(growable: true);
  }

  static List<String> _getInstalledTargets(String toolchain) {
    final res = runCommand("rustup", [
      'target',
      'list',
      '--toolchain',
      toolchain,
      '--installed',
    ]);
    final lines = res.stdout
        .toString()
        .split('\n')
        .where((e) => e.isNotEmpty)
        .toList(growable: true);
    return lines;
  }

  bool _didInstallRustSrcForNightly = false;

  void installRustSrcForNightly() {
    if (_didInstallRustSrcForNightly) {
      return;
    }
    // Useful for -Z build-std
    runCommand(
      "rustup",
      ['component', 'add', 'rust-src', '--toolchain', 'nightly'],
    );
    _didInstallRustSrcForNightly = true;
  }

  static String? executablePath() {
    final envPath = Platform.environment['PATH'];
    final envPathSeparator = Platform.isWindows ? ';' : ':';
    final home = Platform.isWindows
        ? Platform.environment['USERPROFILE']
        : Platform.environment['HOME'];
    final paths = [
      if (home != null) path.join(home, '.cargo', 'bin'),
      if (envPath != null) ...envPath.split(envPathSeparator),
    ];
    for (final p in paths) {
      final rustup = Platform.isWindows ? 'rustup.exe' : 'rustup';
      final rustupPath = path.join(p, rustup);
      if (File(rustupPath).existsSync()) {
        return rustupPath;
      }
    }
    return null;
  }
}
