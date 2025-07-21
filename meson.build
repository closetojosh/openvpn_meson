#Meson port of CMakeLists.txt
project('openvpn', 'c', version: '2.7.0_alpha2', meson_version: '>=1.8.2')
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
  #TODO: Figure out why this is not working
  #message('use_werror: ' + use_werror.to_string())
  if use_werror
    #add_project_arguments('/WX', language: 'c')
  endif
  add_project_arguments([
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

# Global compile definition - equivalent to CMake's add_compile_definitions(HAVE_CONFIG_H)
add_project_arguments('-DHAVE_CONFIG_H', language: 'c')

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
conf.set('TARGET_WIN32', host_sys == 'windows')

conf.set('HAVE_CHSIZE', cc.has_header_symbol('io.h', 'chsize'))
conf.set('HAVE_FCNTL_H', cc.has_header('fcntl.h'))

# Header detection (equivalent to CMake's check_include_files)
conf.set('HAVE_UNISTD_H', cc.has_header('unistd.h'))
conf.set('HAVE_GRP_H', cc.has_header('grp.h'))
conf.set('HAVE_LIBGEN_H', cc.has_header('libgen.h'))
conf.set('HAVE_PWD_H', cc.has_header('pwd.h'))
conf.set('HAVE_SYS_EPOLL_H', cc.has_header('sys/epoll.h'))
conf.set('HAVE_SYSLOG_H', cc.has_header('syslog.h'))
conf.set('HAVE_SYS_MMAN_H', cc.has_header('sys/mman.h'))
conf.set('HAVE_SYS_SOCKET_H', cc.has_header('sys/socket.h'))
conf.set('HAVE_SYS_TIME_H', cc.has_header('sys/time.h'))
conf.set('HAVE_NETINET_IN_H', cc.has_header('netinet/in.h'))
conf.set('HAVE_ARPA_INET_H', cc.has_header('arpa/inet.h'))
conf.set('HAVE_DLFCN_H', cc.has_header('dlfcn.h'))
conf.set('HAVE_DMALLOC_H', cc.has_header('dmalloc.h'))
conf.set('HAVE_ERR_H', cc.has_header('err.h'))
conf.set('HAVE_LINUX_IF_TUN_H', cc.has_header('linux/if_tun.h'))
conf.set('HAVE_LINUX_SOCKIOS_H', cc.has_header('linux/sockios.h'))
conf.set('HAVE_NETDB_H', cc.has_header('netdb.h'))
conf.set('HAVE_NET_IF_H', cc.has_header('net/if.h'))
conf.set('HAVE_NET_IF_TUN_H', cc.has_header('net/if_tun.h'))
conf.set('HAVE_POLL_H', cc.has_header('poll.h'))
conf.set('HAVE_RESOLV_H', cc.has_header('resolv.h'))
conf.set('HAVE_SYS_IOCTL_H', cc.has_header('sys/ioctl.h'))
conf.set('HAVE_SYS_INOTIFY_H', cc.has_header('sys/inotify.h'))
conf.set('HAVE_SYS_UIO_H', cc.has_header('sys/uio.h'))
conf.set('HAVE_SYS_UN_H', cc.has_header('sys/un.h'))
conf.set('HAVE_SYS_WAIT_H', cc.has_header('sys/wait.h'))
conf.set('HAVE_NETINET_IP_H', cc.has_header('netinet/ip.h'))
conf.set('HAVE_MBEDTLS_PSA_CRYPTO_H', cc.has_header('psa/crypto.h'))

conf.set('ROUTE_PATH', find_program('route', required: false).found()? find_program('route', required: false).full_path(): 'ROUTE_PATH-NOTFOUND')

openvpn_dep = []
if enable_lz4
  openvpn_dep += dependency('liblz4', required: true)
endif
if enable_lzo
  openvpn_dep += dependency('lzo2', required: true)
endif

if mbed
  error('mbed is not supported yet')
elif wolfssl
  error('wolfssl is not supported yet')
else
  openvpn_dep += dependency('openssl', required: true)
  #need to add the libraries for windows only for openssl?
  if cc.get_id() == 'msvc'
    openvpn_dep += [
      cc.find_library('ws2_32'), 
      cc.find_library('crypt32'),
      cc.find_library('fwpuclnt'), 
      cc.find_library('iphlpapi'),
      cc.find_library('wininet'), 
      cc.find_library('setupapi'),
      cc.find_library('rpcrt4'), 
      cc.find_library('wtsapi32'),
      cc.find_library('ncrypt'), 
      cc.find_library('bcrypt')
    ]
  endif
endif
#We can skip 347 - 357 cause adding the deps to array and passing it in makes it link
if mbed
  conf.set('ENABLE_CRYPTO_MBEDTLS', true)
elif wolfssl
  conf.set('ENABLE_CRYPTO_WOLFSSL', true)
  conf.set('ENABLE_X509ALTUSERNAME', true)
else
  conf.set('ENABLE_CRYPTO_OPENSSL', true)
  conf.set('ENABLE_X509ALTUSERNAME', true)
endif

#this needs to go into the executable call later
inc_dirs = include_directories(
'src/compat', 
'include')

#375 - 378: I'm not sure if this is needed, maybe add later, it just makes the version header file
python3 = find_program('python3')
config_version_h = custom_target('config-version.h',
  output: ['config-version.h'],
  input: [meson.project_source_root() / 'contrib/cmake/git-version.py'],
  command: [python3, '@INPUT@'],
  build_by_default: true,
  build_always_stale: true
)

conf.set('HAVE_CONFIG_VERSION_H', true)
# This is goofy af, basically the variables on the right are the ones gotten from the m4 file, but they are also stored in conf here but it shouldn't be an issue unless we have collisions
conf.set('OPENVPN_VERSION_RESOURCE', conf.get('VERSION_RESOURCE'))
conf.set('OPENVPN_VERSION_MAJOR', conf.get('PRODUCT_VERSION_MAJOR'))
conf.set('OPENVPN_VERSION_MINOR', conf.get('PRODUCT_VERSION_MINOR'))  
conf.set('OPENVPN_VERSION_PATCH', conf.get('PRODUCT_VERSION_PATCH'))
add_project_arguments('-DDEFAULT_DNS_UPDOWN="@0@"'.format(dns_updown_path), language: 'c')

configure_file(
  input : 'include/openvpn-plugin.h.in',
  output : 'openvpn-plugin.h',
  configuration : conf
)
configure_file(
  input : 'config.h.meson.in',
  output : 'config.h', 
  configuration : conf
)
# I'm not sure what's up with this, it seems to compile adding it to the source_files but doesn't do it for subdirs so i do this for consistency
if build_windows
  windows = import('windows')
  openvpn_resources = windows.compile_resources('src/openvpn/openvpn_win32_resources.rc',
  include_directories: inc_dirs,
  args: ['-DHAVE_CONFIG_H'])
else
  openvpn_resources = []
endif

#ignore plugins from line 382 for now
#This one is for doxygen (leave out for now)
# subdir('doc')
#TODO: Check these later
subdir('src/openvpnmsica')
subdir('src/openvpnserv') 
subdir('src/tapctl')
#We ca remove all the .h files with correpsonding .c files as meson finds them automatically
source_files = []
source_files += config_version_h
source_files += files(
'src/compat/compat-basename.c',
'src/compat/compat-daemon.c',
'src/compat/compat-dirname.c',
'src/compat/compat-gettimeofday.c',
'src/compat/compat-strsep.c',
'src/openvpn/argv.c',
'src/openvpn/base64.c',
'src/openvpn/basic.h',
'src/openvpn/buffer.c',
'src/openvpn/circ_list.h',
'src/openvpn/clinat.c',
'src/openvpn/common.h',
'src/openvpn/comp-lz4.c',
'src/openvpn/comp.c',
'src/openvpn/compstub.c',
'src/openvpn/console.c',
'src/openvpn/console_builtin.c',
'src/openvpn/crypto.c',
'src/openvpn/crypto_backend.h',
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
'src/openvpn/errlevel.h',
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
'src/openvpn/integer.h',
'src/openvpn/interval.c',
'src/openvpn/list.c',
'src/openvpn/lladdr.c',
'src/openvpn/lzo.c',
'src/openvpn/manage.c',
'src/openvpn/mbuf.c',
'src/openvpn/memdbg.h',
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
'src/openvpn/ovpn_dco_win.h',
'src/openvpn/packet_id.c',
'src/openvpn/perf.c',
'src/openvpn/ping.c',
'src/openvpn/pkcs11.c',
'src/openvpn/pkcs11_backend.h',
'src/openvpn/pkcs11_openssl.c',
'src/openvpn/pkcs11_mbedtls.c',
'src/openvpn/platform.c',
'src/openvpn/plugin.c',
'src/openvpn/pool.c',
'src/openvpn/proto.c',
'src/openvpn/proxy.c',
'src/openvpn/ps.c',
'src/openvpn/push.c',
'src/openvpn/pushlist.h',
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
'src/openvpn/ssl_backend.h',
'src/openvpn/ssl_common.h',
'src/openvpn/ssl_openssl.c',
'src/openvpn/ssl_mbedtls.c',
'src/openvpn/ssl_verify.c',
'src/openvpn/ssl_verify_backend.h',
'src/openvpn/ssl_verify_openssl.c',
'src/openvpn/ssl_verify_mbedtls.c',
'src/openvpn/status.c',
'src/openvpn/syshead.h',
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
'src/openvpn/xkey_provider.c'
)
# add dpeendencies to executable
#add other link args here later
openvpn_link_args = []
if cc.get_id() == 'msvc'
  openvpn_link_args += '/MANIFEST:NO'
endif

executable('openvpn', source_files, openvpn_resources,
  dependencies: openvpn_dep,
  include_directories: inc_dirs,
  link_args: openvpn_link_args 
)
#testing later