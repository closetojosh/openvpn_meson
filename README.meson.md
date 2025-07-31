To 



# Requirement:
- Ability to run Windows Docker containers (normally for people with Windows 10 Pro)

# How to setup/compile/unit test:
- `git clone https://github.com/OpenVPN/openvpn`
- `cd` to reposfritory
- Run `docker build -t openvpn-meson-msvc .`
- Run `docker run -it --rm openvpn-meson-msvc`

The default run command will configure meson, compile the project, and then run a suite of unit tests.

# How to establish connection to some VPN server
- Download ovpn file from: https://www.vpngate.net/en/
- Install a version of tap-windows.exe from https://build.openvpn.net/downloads/releases/ and install
- Open cmd as administrator
- openvpn.exe --config "path_to_ovpn_file" --verb 4
- Note: openvpn.exe is usually stored in builddir

# Data acquisition for CMake vs Meson Comparisons:
- Run without setup/compile/test: `docker run -it --rm openvpn-meson-msvc cmd`
- Setup cmd environement: `call %VS_PATH% -arch=x64`
- For build from clean: `powershell.exe -NoProfile -ExecutionPolicy Bypass -File build_clean_comparison.ps1 -Runs 5`
- For iterative builds (we could not get this to work in the Docker container): `powershell.exe -NoProfile -ExecutionPolicy Bypass -File build_iterative_comparison.ps1 -StartCommit f6c95ac -EndCommit 7a2b814 -Runs 5`

