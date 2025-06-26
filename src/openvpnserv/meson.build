if not build_windows
  subdir_done()
endif

openvpnserv_sources = files(
  'common.c',
  'interactive.c',
  'service.c', 'service.h',
  'validate.c', 'validate.h',
  '../tapctl/basic.h',
  '../openvpn/wfp_block.c', '../openvpn/wfp_block.h',
  'openvpnserv_resources.rc',
)

openvpnserv_includes = include_directories(
  '../../include',
  '../openvpn',
  '../compat'
)

executable('openvpnserv', openvpnserv_sources,
  include_directories: openvpnserv_includes,
  dependencies: [],
  install: true,
  c_args: ['-D_UNICODE', '-UNTDDI_VERSION', '-D_WIN32_WINNT=_WIN32_WINNT_VISTA'],
  link_args: ['/MANIFEST:NO', '-ladvapi32', '-luserenv', '-liphlpapi', '-lfwpuclnt', '-lrpcrt4', '-lshlwapi', '-lnetapi32', '-lws2_32', '-lntdll', '-lole32'],
) 