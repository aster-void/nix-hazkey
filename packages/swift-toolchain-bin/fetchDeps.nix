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
  mkdir $PWD/.tmp
  export HOME=$PWD
  export XDG_CACHE_HOME="$PWD/.cache-swiftpm"  # SwiftPM等のローカルキャッシュ先
  export XDG_CONFIG_HOME="$PWD/.config"
  export XDG_STATE_HOME="$PWD/.state"

  # copy phase
  cp ${src}/Package.swift ${src}/Package.resolved .

  # download phase
  swift package --disable-dependency-cache --skip-update resolve

  # patch phase
  find .build -type f -path "*/hooks/*.sample" -exec rm {} +

  # install phase
  cp -r .build $out
''
