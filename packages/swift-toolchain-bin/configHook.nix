{writeTextFile}:
writeTextFile {
  name = "swift-config-hook";
  destination = "/nix-support/setup-hook";
  text = ''
    swiftInstallPhase() {
      if [ -z "''${swiftDeps:-}" ]; then
        echo "swiftDeps is not set; skip swiftInstallPhase" >&2
        return 0
      fi

      pushd "''${swiftRoot:-.}"
      mkdir -p .build
      cp -rT "$swiftDeps" .build
      popd
    }

    preBuildPhases+=" swiftInstallPhase"
  '';
}
