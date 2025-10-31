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
      local buildSrc="$swiftDeps/build"
      local cacheSrc="$swiftDeps/cache"

      if [ -d "$buildSrc" ]; then
        rm -rf .build
        mkdir -p .build
        cp -rT "$buildSrc" .build
      fi

      if [ -d "$cacheSrc" ]; then
        mkdir -p .cache
        cp -rT "$cacheSrc" .cache
      fi
      popd
    }

    preBuildPhases+=" swiftInstallPhase"
  '';
}
