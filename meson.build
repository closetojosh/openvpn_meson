#Meson port of CMakeLists.txt
project('openvpn', 'c', meson_version: '>=1.8.2')
skip = true

########################
# policy checks
########################
host_sys = host_machine.system()

if not skip# skip 26-32
    if host_sys != 'windows' and not get_option('unsupported_builds')
    error('On Unix the supported build is autotools. Pass -Dunsupported_builds=true if you really want Meson/CMake style builds.')
    endif

    # Guard against mixing autoconf in‑tree builds and Meson out‑of‑tree
    fs = import('fs')  # Pull in Meson’s file-system helpers
    if fs.exists(join_paths(meson.project_source_root(), 'config.h'))
    error('Top-level source dir contains a config.h produced by autoconf – please clean the tree before configuring with Meson.')
    endif
endif
########################
# Build platform variables (temporary, add logic to detect the platform later)
########################
build_windows = true
build_linux = false
build_freebsd = false
build_openbsd = false
build_sunos = false
build_apple = false

########################
# User‑configurable options
########################
# Dependencies

mbed = get_option('mbed')
mbed_include_path = get_option('mbed_include_path')
mbed_library_path = get_option('mbed_library_path')
wolfssl = get_option('wolfssl')
enable_lz4 = get_option('enable_lz4')
enable_lzo = get_option('enable_lzo')
enable_pkcs11 = get_option('enable_pkcs11')
use_werror = get_option('use_werror')
fake_android = get_option('fake_android')
enable_dns_updown = get_option('enable_dns_updown')
dns_updown_path = get_option('dns_updown_path')
prefix = get_option('prefix')
if dns_updown_path == ''
  dns_updown_path = join_paths(prefix, 'libexec', 'openvpn', 'dns-updown')
endif
plugin_dir = get_option('plugin_dir')
if plugin_dir == ''
  plugin_dir = join_paths(prefix, 'lib', 'openvpn', 'plugins')
endif
enable_compile_commands = get_option('enable_compile_commands') 


########################
# Toolchain‑dependent compile / link arguments
########################
# skip 50 - 71


cc = meson.get_compiler('c')
common_c_args   = ['-Wall', '-Wuninitialized']
common_link_args = []

message(cc.get_id())
assert(cc.get_id() == 'msvc', 'This project only support the msvc compiler.')
if cc.get_id() == 'msvc'
    common_c_args  += ['/MP', '/W2', '/sdl', '/Qspectre', '/guard:cf', '/FC', '/ZH:SHA_256']
    common_link_args += ['/Brepro']
    # Release‑only flags reproduced with vs_module_defs in Meson
    add_languages('cpp', required : false)     # ensures cpp compiler exists for future flags
endif



common_c_args = ['-Wall','-Wuninitialized']
if cc.has_argument('-Wno-stringop-truncation')
  common_c_args += ['-Wno-stringop-truncation']
endif
add_project_arguments(common_c_args, language:'c')

# Dependencies list
openvpn_deps = []

# Crypto dependencies
if not mbed and not wolfssl
    openssl_subproject = subproject('openssl')
    openssl_dep = openssl_subproject.get_variable('openssl_dep')
    openvpn_deps += [openssl_dep]
else
    openssl_dep = disabler()
endif

# Alternative crypto libraries (disabled for now)
mbedtls_dep = disabler()
wolfssl_dep = disabler()

# Compression dependencies
if get_option('enable_lz4')
    lz4_subproject = subproject('lz4')
    lz4_dep = lz4_subproject.get_variable('liblz4_dep')
    openvpn_deps += [lz4_dep]
else
    lz4_dep = disabler()
endif

if get_option('enable_lzo')
    lzo_subproject = subproject('lzo2')
    lzo_dep = lzo_subproject.get_variable('lzo2_dep')
    openvpn_deps += [lzo_dep]
else
    lzo_dep = disabler()
endif

# PKCS11 support (disabled for now)
# pkcs11_dep = disabler()

# Linux-specific dependencies
if host_sys == 'linux'
    libcapng_subproject = subproject('libcap-ng')
    libcapng_dep = libcapng_subproject.get_variable('libcapng_dep')
    openvpn_deps += [libcapng_dep]
    
    libnl_subproject = subproject('libnl')
    libnl_dep = libnl_subproject.get_variable('libnl_dep')
    libnl_genl_dep = libnl_subproject.get_variable('libnl_genl_dep')
    openvpn_deps += [libnl_dep, libnl_genl_dep]
else
    libcapng_dep = disabler()
    libnl_dep = disabler()
    libnl_genl_dep = disabler()
endif

# Testing dependencies
if get_option('enable_testing')
    cmocka_subproject = subproject('cmocka')
    cmocka_dep = cmocka_subproject.get_variable('cmocka_dep')
    openvpn_deps += [cmocka_dep]
else
    cmocka_dep = disabler()
endif

# Configuration data
conf_data = configuration_data()
conf_data.set('PLUGIN_DIR', get_option('plugin_dir'))
conf_data.set('ENABLE_DNS_UPDOWN_BY_DEFAULT', get_option('enable_dns_updown'))
if dns_updown_path == ''
  dns_updown_path = join_paths(get_option('prefix'), get_option('libexecdir'), 'openvpn', 'dns-updown')
endif

conf_data.set('DNS_UPDOWN_PATH', get_option('dns_updown_path'))
#compilerflags
if build_windows
  # Compile definitions
  add_project_arguments([
    '-DWIN32_LEAN_AND_MEAN',
    '-D_CRT_SECURE_NO_WARNINGS',
    '-D_CRT_NONSTDC_NO_DEPRECATE',
    '-D_WINSOCK_DEPRECATED_NO_WARNINGS'
  ], language: 'c')
  
  # MSVC-specific compile options
  if cc.get_id() == 'msvc'
    # Werror handling
    if get_option('use_werror')
      add_project_arguments('/WX', language: 'c')
    endif
    
    add_project_arguments([
      '/MP',          # Multi-processor compilation
      '/W2',          # Warning level 2
      '/sdl',         # Enable additional security checks
      '/Qspectre',    # Spectre mitigation
      '/guard:cf',    # Control Flow Guard
      '/FC',          # Full path in diagnostics
      '/ZH:SHA_256'   # Hash algorithm for file checksums
    ], language: 'c')
    
    # Release-specific compile options
    if get_option('buildtype') == 'release'
      add_project_arguments([
        '/GL',        # Whole Program Optimization
        '/Oi',        # Generate Intrinsic Functions
        '/Gy',        # Enable Function-Level Linking
        '/Zi'         # Generate Debug Information
      ], language: 'c')
    endif
    
    # Basic link options
    add_project_link_arguments('/Brepro', language: 'c')
    
    # Release-specific link options
    if get_option('buildtype') == 'release'
      add_project_link_arguments([
        '/LTCG:incremental',  # Link Time Code Generation
        '/DEBUG:FULL',        # Generate full debug info
        '/OPT:REF',          # Remove unreferenced functions
        '/OPT:ICF'           # Identical COMDAT Folding
      ], language: 'c')
      
      # Platform-specific release options
      if host_machine.cpu_family() == 'x86_64' or host_machine.cpu_family() == 'x86'
        add_project_link_arguments('/CETCOMPAT', language: 'c')
      endif
    endif
  endif
  
  # Windows libraries
  add_project_link_arguments(['-lws2_32', '-lwinmm'], language: 'c')
endif

if get_option('use_werror')
  add_project_arguments('-Werror', language: 'c')
endif

if build_linux or build_freebsd or build_openbsd or build_sunos or build_apple
  add_project_arguments('-Wall', '-Wuninitialized', language: 'c')
endif

enable_dco = false
if build_windows or build_linux or build_freebsd
  enable_dco = true
endif

target_linux = build_linux

target_win32 = build_windows

target_darwin = build_apple

openvpn_sources = files(
  'src/compat/compat-basename.c',
  'src/compat/compat-daemon.c',
  'src/compat/compat-dirname.c',
  'src/compat/compat-gettimeofday.c',
  'src/compat/compat-strsep.c',
  'src/openvpn/argv.c',
  'src/openvpn/base64.c',
  'src/openvpn/buffer.c',
  'src/openvpn/clinat.c',
  'src/openvpn/comp-lz4.c',
  'src/openvpn/comp.c',
  'src/openvpn/compstub.c',
  'src/openvpn/console.c',
  'src/openvpn/console_builtin.c',
  'src/openvpn/crypto.c',
  'src/openvpn/crypto_epoch.c',
  'src/openvpn/crypto_openssl.c',
  'src/openvpn/crypto_mbedtls.c',
  'src/openvpn/cryptoapi.c',
  'src/openvpn/dco.c',
  'src/openvpn/dco_win.c',
  'src/openvpn/dco_linux.c',
  'src/openvpn/dco_freebsd.c',
  'src/openvpn/dhcp.c',
  'src/openvpn/dns.c',
  'src/openvpn/env_set.c',
  'src/openvpn/error.c',
  'src/openvpn/event.c',
  'src/openvpn/fdmisc.c',
  'src/openvpn/forward.c',
  'src/openvpn/fragment.c',
  'src/openvpn/gremlin.c',
  'src/openvpn/helper.c',
  'src/openvpn/httpdigest.c',
  'src/openvpn/init.c',
  'src/openvpn/interval.c',
  'src/openvpn/list.c',
  'src/openvpn/lladdr.c',
  'src/openvpn/lzo.c',
  'src/openvpn/manage.c',
  'src/openvpn/mbuf.c',
  'src/openvpn/misc.c',
  'src/openvpn/mroute.c',
  'src/openvpn/mss.c',
  'src/openvpn/mstats.c',
  'src/openvpn/mtcp.c',
  'src/openvpn/mtu.c',
  'src/openvpn/mudp.c',
  'src/openvpn/multi.c',
  'src/openvpn/multi_io.c',
  'src/openvpn/ntlm.c',
  'src/openvpn/occ.c',
  'src/openvpn/openvpn.c',
  'src/openvpn/options.c',
  'src/openvpn/options_util.c',
  'src/openvpn/otime.c',
  'src/openvpn/packet_id.c',
  'src/openvpn/perf.c',
  'src/openvpn/ping.c',
  'src/openvpn/pkcs11.c',
  'src/openvpn/pkcs11_openssl.c',
  'src/openvpn/pkcs11_mbedtls.c',
  'src/openvpn/platform.c',
  'src/openvpn/plugin.c',
  'src/openvpn/pool.c',
  'src/openvpn/proto.c',
  'src/openvpn/proxy.c',
  'src/openvpn/ps.c',
  'src/openvpn/push.c',
  'src/openvpn/reflect_filter.c',
  'src/openvpn/reliable.c',
  'src/openvpn/route.c',
  'src/openvpn/run_command.c',
  'src/openvpn/schedule.c',
  'src/openvpn/session_id.c',
  'src/openvpn/shaper.c',
  'src/openvpn/sig.c',
  'src/openvpn/socket.c',
  'src/openvpn/socks.c',
  'src/openvpn/ssl.c',
  'src/openvpn/ssl_openssl.c',
  'src/openvpn/ssl_mbedtls.c',
  'src/openvpn/ssl_verify.c',
  'src/openvpn/ssl_verify_openssl.c',
  'src/openvpn/ssl_verify_mbedtls.c',
  'src/openvpn/status.c',
  'src/openvpn/tls_crypt.c',
  'src/openvpn/tun.c',
  'src/openvpn/tun_afunix.c',
  'src/openvpn/networking_sitnl.c',
  'src/openvpn/networking_freebsd.c',
  'src/openvpn/auth_token.c',
  'src/openvpn/ssl_ncp.c',
  'src/openvpn/ssl_pkt.c',
  'src/openvpn/ssl_util.c',
  'src/openvpn/vlan.c',
  'src/openvpn/wfp_block.c',
  'src/openvpn/win32.c',
  'src/openvpn/win32-util.c',
  'src/openvpn/xkey_helper.c',
  'src/openvpn/xkey_provider.c',
)

executable('openvpn', openvpn_sources,
  dependencies: openvpn_deps,
  install: true,
)
