if not build_windows
  subdir_done()
endif

openvpnmsica_sources = files(
  'dllmain.c',
  'msiex.c', 'msiex.h',
  'msica_arg.c', 'msica_arg.h',
  'openvpnmsica.c', 'openvpnmsica.h',
  '../tapctl/basic.h',
  '../tapctl/error.c', '../tapctl/error.h',
  '../tapctl/tap.c', '../tapctl/tap.h',
  'openvpnmsica_resources.rc',
)

openvpnmsica_includes = include_directories(
  '../../include',
  '../compat'
)

shared_library('openvpnmsica', openvpnmsica_sources,
  include_directories: openvpnmsica_includes,
  dependencies: [],
  install: true,
  c_args: ['-D_UNICODE', '-UNTDDI_VERSION', '-D_WIN32_WINNT=_WIN32_WINNT_VISTA'],
  link_args: ['/MANIFEST:NO', '-ladvapi32', '-lole32', '-lmsi', '-lsetupapi', '-liphlpapi', '-lshell32', '-lshlwapi', '-lversion', '-lnewdev'],
) 