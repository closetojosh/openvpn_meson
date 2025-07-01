#Meson port of CMakeLists.txt
project('openvpn', 'c', meson_version: '>=1.8.2')
skip = true

########################
# policy checks
########################
host_sys = host_machine.system()
cpu = host_machine.cpu_family()

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

mbed              = get_option('mbed')
mbed_include_path = get_option('mbed_include_path')
mbed_library_path = get_option('mbed_library_path')
wolfssl           = get_option('wolfssl')
enable_lz4        = get_option('enable_lz4')
enable_lzo        = get_option('enable_lzo')
enable_pkcs11     = get_option('enable_pkcs11')
use_werror        = get_option('use_werror')
fake_android      = get_option('fake_android')
enable_dns_updown = get_option('enable_dns_updown')
dns_updown_path   = get_option('dns_updown_path')
prefix            = get_option('prefix')
buildtype = get_option('buildtype')


if dns_updown_path == ''
  dns_updown_path = join_paths(prefix, 'libexec', 'openvpn', 'dns-updown')
endif
plugin_dir        = get_option('plugin_dir')
if plugin_dir == ''
  plugin_dir = join_paths(prefix, 'lib', 'openvpn', 'plugins')
endif
enable_compile_commands = get_option('enable_compile_commands') 


########################
# Toolchain‑dependent compile / link arguments
########################
# skip 50 - 71


cc = meson.get_compiler('c')

if cc.get_id() == 'msvc'
  add_project_arguments([
      '-D_CRT_SECURE_NO_WARNINGS',
      '-D_CRT_NONSTDC_NO_DEPRECATE',
      '-D_WINSOCK_DEPRECATED_NO_WARNINGS',
  ], language: 'c')
  
  if use_werror
    add_project_arguments('/WX', language: 'c')
  endif
  add_project_arguments([
    'std=c11',
    '/MP',         # Multi‐processor compile  
    '/W2',         # Warning level 2  
    '/sdl',        # SDL security checks  
    '/Qspectre',   # Spectre mitigation  
    '/guard:cf',   # Control‐flow guard  
    '/FC',         # Full paths in diagnostics  
    '/ZH:SHA_256'  # Deterministic PDB hashing 
  ], language: 'c')
  if buildtype == 'release'
    add_project_arguments([
      '/GL',   # Whole‐program optimization  
      '/Oi',   # Intrinsic expansion  
      '/Gy',   # Function‐level linking  
      '/Zi'    # Full debug info in release  
    ], language: 'c')
  endif

  add_project_link_arguments([
    '/Brepro'  # reproducible builds
  ], language: 'c')

  if buildtype == 'release'
    add_project_link_arguments([
      '/LTCG:incremental',  # incremental link-time codegen
      '/DEBUG:FULL',        # full PDB debug info
      '/OPT:REF',           # remove unreferenced code/data
      '/OPT:ICF'            # fold identical COMDAT sections
    ], language: 'c' )
  endif
  if host_sys == 'windows' and buildtype == 'release' and (cpu == 'x86' or cpu == 'x86_64')
    add_project_link_arguments('/CETCOMPAT', language: 'c')
  endif
endif

conf = configuration_data()
conf.set('PRODUCT_NAME', 'OpenVPN')
conf.set('PRODUCT_TARNAME', 'openvpn')                 # PRODUCT_TARNAME
conf.set('PRODUCT_VERSION_MAJOR', 2)
conf.set('PRODUCT_VERSION_MINOR', 7)
conf.set('PRODUCT_VERSION_PATCH', '_alpha2')
conf.set('BUGREPORT', 'openvpn-users@lists.sourceforge.net')   # PRODUCT_BUGREPORT
conf.set('VERSION_RESOURCE', '2,7,0,0')                        # PRODUCT_VERSION_RESOURCE
conf.set('TAP_WIN_COMPONENT_ID', 'tap0901')                   # PRODUCT_TAP_WIN_COMPONENT_ID
conf.set('TAP_WIN_MIN_MAJOR', '9')                            # PRODUCT_TAP_WIN_MIN_MAJOR
conf.set('TAP_WIN_MIN_MINOR', '9')                            # PRODUCT_TAP_WIN_MIN_MINOR

# linux specific 
conf.set('ENABLE_DCO', host_sys == 'windows')
conf.set('PATH_SEPARATOR', '\\\\')
conf.set('TARGET_WIN32', host_sys == 'windows') ## TODO, look at version.h.in

conf.set('HAVE_CHSIZE', cc.has_header_symbol('io.h', 'chsize'))
conf.set('HAVE_FCNTL_H', cc.has_header('fcntl.h'))


conf.set('ROUTE_PATH', find_program('route', required: false).found()? find_program('route', required: false).full_path(): 'ROUTE_PATH-NOTFOUND')

openvpn_dep = []
if enable_lz4
  openvpn_dep += dependency('liblz4', required: true)
endif
if enable_lzo
  openvpn_dep += dependency('lzo2', required: true)
endif
# I DON"T KNOW HOW TO GE TTHIS TO WORK
# I AM NOW at line 300
# if enable_pkcs11
#   openvpn_dep += dependency('libpkcs11-helper-1', required: true)
# endif

configure_file(
  input : 'version.h.in',
  output : 'version.h',
  configuration : conf
)

# add dpeendencies to executable