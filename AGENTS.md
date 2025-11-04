# AGENTS.md

- Prefer mutating build environment > mutating environment variables > mutating build command > apatching config files
- replicate a "standard" build environment.
  - so buildFHSEnv is necessary. don't try to delete it.
- for building, use exactly this command: `nix build --log-format bar .#fcitx5-hazkey_git`. do not use any other command.
  - Don't pipe it. don't tail it.

the author says this is the build command:

```sh
git clone --recursive https://github.com/7ka-Hiira/fcitx5-hazkey.git
cd fcitx5-hazkey
mkdir build && cd build
cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr -G Ninja ..
ninja
sudo ninja install
````
