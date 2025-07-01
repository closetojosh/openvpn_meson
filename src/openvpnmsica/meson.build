if not build_windows
  subdir_done()
endif

windows = import('windows')

openvpnmsica_sources = files(
  'dllmain.c',
  'msiex.c', 'msiex.h',
  'msica_arg.c', 'msica_arg.h',
  'openvpnmsica.c', 'openvpnmsica.h',
  '../tapctl/basic.h',
  '../tapctl/error.c', '../tapctl/error.h',
  '../tapctl/tap.c', '../tapctl/tap.h'
)

openvpnmsica_resources = windows.compile_resources('openvpnmsica_resources.rc')

openvpnmsica_includes = include_directories(
  '../..',
  '../../include',
  '../compat'
)

openvpnmsica_c_args = ['-D_UNICODE', '-UNTDDI_VERSION', '-D_WIN32_WINNT=_WIN32_WINNT_VISTA']
openvpnmsica_link_args = []

# MSVC specific options
if get_option('b_vscrt') != 'none'
  if get_option('buildtype') == 'release'
    openvpnmsica_c_args += ['/MT']
  else
    openvpnmsica_c_args += ['/MTd']
  endif
endif

# MINGW specific options  
if cc.get_id() == 'gcc' and build_machine.system() == 'windows'
  openvpnmsica_c_args += ['-municode']
  openvpnmsica_link_args += ['-municode', '-Wl,--kill-at']
endif

openvpnmsica_deps = [
  cc.find_library('advapi32'),
  cc.find_library('ole32'), 
  cc.find_library('msi'),
  cc.find_library('setupapi'),
  cc.find_library('iphlpapi'),
  cc.find_library('shell32'),
  cc.find_library('shlwapi'), 
  cc.find_library('version'),
  cc.find_library('newdev')
]

shared_library('openvpnmsica', openvpnmsica_sources, openvpnmsica_resources,
  include_directories: openvpnmsica_includes,
  dependencies: openvpnmsica_deps,
  install: true,
  c_args: openvpnmsica_c_args,
  link_args: openvpnmsica_link_args
) 