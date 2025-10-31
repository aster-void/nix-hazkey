{
  swift-toolchain,
  runCommand,
  cacert,
}: {
  hash ? "",
  hashAlgo ? "sha256",
  src,
}:
runCommand "swift-fetch-deps" {
  nativeBuildInputs = [
    swift-toolchain
    cacert
  ];
  outputHashAlgo = hashAlgo;
  outputHashMode = "recursive";
  outputHash = hash;
} ''
  export TMPDIR=$PWD/.tmp
  mkdir -p "$PWD/.tmp"
  export HOME=$PWD
  export XDG_CACHE_HOME="$PWD/.cache-swiftpm"  # SwiftPM等のローカルキャッシュ先
  mkdir -p "$XDG_CACHE_HOME"
  export XDG_CONFIG_HOME="$PWD/.config"
  export XDG_STATE_HOME="$PWD/.state"

  # copy phase
  cp ${src}/Package.swift ${src}/Package.resolved .

  # download phase
  swift package --skip-update resolve

  # patch phase
  find .build -type f -path "*/hooks/*.sample" -exec rm {} +
  find "$XDG_CACHE_HOME" -type f -path "*/hooks/*.sample" -exec rm {} +
  find .build -type d -path "*/.git/hooks" -prune -exec rm -rf {} +
  find "$XDG_CACHE_HOME" -type d -path "*/.git/hooks" -prune -exec rm -rf {} +
  rm -rf "$XDG_CACHE_HOME"/org.swift.foundation.URLCache
  rm -rf "$XDG_CACHE_HOME"/org.swift.swiftpm/manifests
  rm -rf "$XDG_CACHE_HOME"/clang

  # install phase
  mkdir -p $out/build $out/cache
  cp -r .build/. $out/build
  cp -r "$XDG_CACHE_HOME"/. $out/cache
''
