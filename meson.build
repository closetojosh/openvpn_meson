#Meson port of CMakeLists.txt
project('openvpn', 'c',
  version: '2.6.0',
  meson_version: '>=1.8.2',
  default_options: [
    'buildtype=release',
    'warning_level=2',
    'werror=true'
  ]
)

# Build configuration options
build_windows = host_machine.system() == 'windows'
build_linux = host_machine.system() == 'linux'
build_freebsd = host_machine.system() == 'freebsd'
build_openbsd = host_machine.system() == 'openbsd'
build_sunos = host_machine.system() == 'sunos'
build_apple = host_machine.system() == 'darwin'
build_android = host_machine.system() == 'android' or get_option('fake_android')

# Dependencies
mbed_enabled = get_option('mbed')
wolfssl_enabled = get_option('wolfssl')

openssl_dep = dependency('openssl', version: '>=1.1.1', required: not mbed_enabled and not wolfssl_enabled, method: ['pkg-config', 'cmake'])

mbedtls_dep = dependency('mbedtls', required: mbed_enabled, method: 'pkg-config',
    include_type: 'system',
    static: false)

wolfssl_dep = dependency('wolfssl', required: wolfssl_enabled, method: 'pkg-config',
    include_type: 'system',
    static: false)

lz4_dep = dependency('liblz4', required: get_option('enable_lz4'))
lzo_dep = dependency('lzo2', required: get_option('enable_lzo'))
pkcs11_dep = dependency('libpkcs11-helper-1', required: get_option('enable_pkcs11'))

# Configuration data
conf_data = configuration_data()
conf_data.set('PLUGIN_DIR', get_option('plugin_dir'))
conf_data.set('ENABLE_DNS_UPDOWN_BY_DEFAULT', get_option('enable_dns_updown'))
conf_data.set('DNS_UPDOWN_PATH', get_option('dns_updown_path'))

if build_windows
  add_project_arguments('-DWIN32_LEAN_AND_MEAN', language: 'c')
  add_project_link_arguments('-lws2_32', '-lwinmm', language: 'c')
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
  dependencies: [openssl_dep, lz4_dep, lzo_dep, pkcs11_dep, mbedtls_dep, wolfssl_dep],
  install: true,
)
