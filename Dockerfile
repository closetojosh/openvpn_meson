FROM mcr.microsoft.com/windows/servercore:ltsc2019

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

# 1) Install VS Build Tools
RUN Invoke-WebRequest \
      -Uri https://aka.ms/vs/17/release/vs_buildtools.exe \
      -OutFile vs_buildtools.exe ; \
    Start-Process vs_buildtools.exe \
      -Wait \
      -ArgumentList '--quiet','--wait','--norestart','--nocache','--installPath','C:\BuildTools','--add','Microsoft.VisualStudio.Workload.VCTools','--add','Microsoft.VisualStudio.Component.Windows10SDK.19041','--includeRecommended' ; \
    Remove-Item vs_buildtools.exe

# 2) Install Python into C:\Python311
RUN Invoke-WebRequest \
      -Uri https://www.python.org/ftp/python/3.11.5/python-3.11.5-amd64.exe \
      -OutFile python-installer.exe ; \
    Start-Process python-installer.exe \
      -Wait \
      -ArgumentList '/quiet','InstallAllUsers=1','PrependPath=1','Include_test=0','TargetDir=C:\Python311' ; \
    Remove-Item python-installer.exe

# 3) Set up PATH for our custom Python
ENV SSL_CERT_FILE="C:/Python311/Lib/site-packages/certifi/cacert.pem"

# 4) pip → meson, ninja, certifi
RUN python -m pip install --upgrade pip
RUN python -m pip install meson ninja certifi

# 5) Install MinGit for \git apply\
RUN Invoke-WebRequest \
      -Uri https://github.com/git-for-windows/git/releases/download/v2.45.1.windows.1/MinGit-2.45.1-64-bit.zip \
      -OutFile mingit.zip ; \
    Expand-Archive mingit.zip -DestinationPath C:\MinGit ; \
    Remove-Item mingit.zip

RUN C:\MinGit\cmd\git.exe config --global --add safe.directory C:/openvpn

RUN powershell -Command New-Item -ItemType Directory -Force -Path 'C:\OpenVPN\vcpkg'
RUN C:\MinGit\cmd\git.exe clone https://github.com/microsoft/vcpkg.git C:\OpenVPN\vcpkg

ENV PATH="C:\\Windows\\System32\\WindowsPowerShell\\v1.0;C:\\Python311;C:\\Python311\\Scripts;C:\\MinGit\\cmd;C:\\MinGit\\usr\\bin;C:\\Program Files (x86)\\Windows Kits\\10\\bin\\10.0.19041.0\\x64;${PATH}"
ENV LIB="C:\\Program Files (x86)\\Windows Kits\\10\\Lib\\10.0.19041.0\\um\\x64;C:\\Program Files (x86)\\Windows Kits\\10\\Lib\\10.0.19041.0\\ucrt\\x64"
ENV INCLUDE="C:\\Program Files (x86)\\Windows Kits\\10\\Include\\10.0.19041.0\\um;C:\\Program Files (x86)\\Windows Kits\\10\\Include\\10.0.19041.0\\ucrt;C:\\Program Files (x86)\\Windows Kits\\10\\Include\\10.0.19041.0\\shared"

# 6) VS setup helper
ENV VS_PATH=C:\\BuildTools\\Common7\\Tools\\VsDevCmd.bat

WORKDIR C:\\OpenVPN\\openvpn
COPY . .

CMD ["cmd", "/c", "call %VS_PATH% -arch=x64 && meson setup builddir --wipe && meson compile -C builddir && meson test -C builddir"]

