import 'dart:io';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;

import 'artifacts_provider.dart';
import 'builder.dart';
import 'cargo.dart';
import 'options.dart';
import 'rustup.dart';
import 'target.dart';

final _log = Logger('precompile_local_binaries');

class PrecompileLocalBinaries {
  PrecompileLocalBinaries({
    required this.manifestDir,
    required this.targets,
    this.androidSdkLocation,
    this.androidNdkVersion,
    this.androidMinSdkVersion,
    this.tempDir,
  });

  final String manifestDir;
  final List<Target> targets;
  final String? androidSdkLocation;
  final String? androidNdkVersion;
  final int? androidMinSdkVersion;
  final String? tempDir;

  static String fileName(
    Target target,
    String name,
  ) {
    return '${target.rust}_$name';
  }

  static String signatureFileName(
    Target target,
    String name,
  ) {
    return '${target.rust}_$name.sig';
  }

  Future<void> run() async {
    final crateInfo = CrateInfo.load(manifestDir);

    final targets = List.of(this.targets);
    if (targets.isEmpty) {
      targets.addAll([
        ...Target.buildableTargets(),
        if (androidSdkLocation != null) ...Target.androidTargets(),
      ]);
    }

    _log.info('Precompiling binaries for $targets');

    final tempDir = this.tempDir != null
        ? Directory(this.tempDir!)
        : Directory.systemTemp.createTempSync('precompiled_');

    tempDir.createSync(recursive: true);

    final crateOptions = CargokitCrateOptions.load(manifestDir: manifestDir);

    final buildEnvironment = BuildEnvironment(
      configuration: BuildConfiguration.release,
      crateOptions: crateOptions,
      targetTempDir: tempDir.path,
      manifestDir: manifestDir,
      crateInfo: crateInfo,
      isAndroid: androidSdkLocation != null,
      androidSdkPath: androidSdkLocation,
      androidNdkVersion: androidNdkVersion,
      androidMinSdkVersion: androidMinSdkVersion,
    );

    final rustup = Rustup();

    for (final target in targets) {
      final artifactNames = getArtifactNames(
          target: target, libraryName: crateInfo.packageName, remote: true);

      _log.info('Building for $target');

      final builder =
          RustBuilder(target: target, environment: buildEnvironment);
      builder.prepare(rustup);
      final res = await builder.build();

      for (final name in artifactNames) {
        final file = File(path.join(res, name));
        if (!file.existsSync()) {
          throw Exception('Missing artifact: ${file.path}');
        }

        String destinationPath = "../binary/$target/$name";
        File destinationFile = File(destinationPath);
        destinationFile.parent.createSync(recursive: true);
        file.copySync(destinationPath);
      }
    }

    _log.info('Cleaning up');
    tempDir.deleteSync(recursive: true);
  }
}
