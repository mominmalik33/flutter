// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:platform/platform.dart';
import 'package:process/process.dart';

import 'package:dev_tools/roll_dev.dart' show rollDev;
import 'package:dev_tools/repository.dart';
import 'package:dev_tools/version.dart';

import './common.dart';

void main() {
  group('roll-dev', () {
    TestStdio stdio;
    Platform platform;
    ProcessManager processManager;
    FileSystem fileSystem;
    const String usageString = 'Usage: flutter conductor.';

    Checkouts checkouts;
    Repository frameworkUpstream;
    Repository framework;

    setUp(() {
      platform = const LocalPlatform();
      fileSystem = const LocalFileSystem();
      processManager = const LocalProcessManager();
      stdio = TestStdio(verbose: true);
      checkouts = Checkouts(
        fileSystem: fileSystem,
        platform: platform,
        processManager: processManager,
      );

      frameworkUpstream = checkouts.addRepo(
        repoType: RepositoryType.framework,
        name: 'framework-upstream',
        stdio: stdio,
        platform: platform,
        localUpstream: true,
        fileSystem: fileSystem,
        useExistingCheckout: false,
      );

      // This repository has [frameworkUpstream] set as its push/pull remote.
      framework = frameworkUpstream.cloneRepository('test-framework');
    });

    test('increment m', () {
      final Version initialVersion = framework.flutterVersion();

      final String latestCommit = framework.authorEmptyCommit();

      final FakeArgResults fakeArgResults = FakeArgResults(
        level: 'm',
        commit: latestCommit,
        remote: 'origin',
      );

      expect(
        rollDev(
          usage: usageString,
          argResults: fakeArgResults,
          stdio: stdio,
          fileSystem: fileSystem,
          platform: platform,
          repository: framework,
        ),
        true,
      );
      expect(
        stdio.stdout,
        contains(RegExp(r'Publishing Flutter \d+\.\d+\.\d+-\d+\.\d+\.pre \(')),
      );

      final Version finalVersion = framework.flutterVersion();
      expect(
        initialVersion.toString() != finalVersion.toString(),
        true,
        reason: 'initialVersion = $initialVersion; finalVersion = $finalVersion',
      );
      expect(finalVersion.n, 0);
      expect(finalVersion.commits, null);
    });

    test('increment y', () {
      final Version initialVersion = framework.flutterVersion();

      final String latestCommit = framework.authorEmptyCommit();

      final FakeArgResults fakeArgResults = FakeArgResults(
        level: 'y',
        commit: latestCommit,
        remote: 'origin',
      );

      expect(
        rollDev(
          usage: usageString,
          argResults: fakeArgResults,
          stdio: stdio,
          fileSystem: fileSystem,
          platform: platform,
          repository: framework,
        ),
        true,
      );
      expect(
        stdio.stdout,
        contains(RegExp(r'Publishing Flutter \d+\.\d+\.\d+-\d+\.\d+\.pre \(')),
      );

      final Version finalVersion = framework.flutterVersion();
      expect(
        initialVersion.toString() != finalVersion.toString(),
        true,
        reason: 'initialVersion = $initialVersion; finalVersion = $finalVersion',
      );
      expect(finalVersion.y, initialVersion.y + 1);
      expect(finalVersion.z, 0);
      expect(finalVersion.m, 0);
      expect(finalVersion.n, 0);
      expect(finalVersion.commits, null);
    });
  }, onPlatform: <String, dynamic>{
    'windows': const Skip('Flutter Conductor only supported on macos/linux'),
  // TODO(fujino): re-enable once
  // https://github.com/flutter/flutter/issues/70652 is resolved
  }, skip: true);
}
