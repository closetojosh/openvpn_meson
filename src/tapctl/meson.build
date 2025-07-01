if not build_windows
  subdir_done()
endif

windows = import('windows')

tapctl_sources = files(
  'basic.h',
  'error.c', 'error.h',
  'main.c',
  'tap.c', 'tap.h'
)

tapctl_resources = windows.compile_resources('tapctl_resources.rc')

tapctl_includes = include_directories(
  '../../include',
  '../compat'
)

executable('tapctl', tapctl_sources, tapctl_resources,
  include_directories: tapctl_includes,
  dependencies: [],
  install: true,
  c_args: ['-D_UNICODE', '-UNTDDI_VERSION', '-D_WIN32_WINNT=_WIN32_WINNT_VISTA'],
  link_args: ['/MANIFEST:NO', '-ladvapi32', '-lole32', '-lsetupapi'],
) 