include(FindPackageHandleStandardArgs)

find_package(PkgConfig REQUIRED)

pkg_check_modules(Wayland_PKG_CONFIG QUIET "wayland-client")
find_path(Wayland_INCLUDE_DIRS NAMES "wayland-client.h" HINTS ${Wayland_PKG_CONFIG_INCLUDE_DIRS})
find_library(Wayland_LIBRARIES NAMES "wayland-client" HINTS ${Wayland_PKG_CONFIG_LIBRARY_DIRS})
set(Wayland_DEFINITIONS ${Wayland_PKG_CONFIG_DEFINITIONS})

add_library(Wayland UNKNOWN IMPORTED)
set_target_properties(Wayland PROPERTIES IMPORTED_LOCATION "${Wayland_LIBRARIES}" INTERFACE_COMPILE_OPTIONS "${Wayland_DEFINITIONS}" INTERFACE_INCLUDE_DIRECTORIES "${Wayland_INCLUDE_DIRS}")
find_package_handle_standard_args(Wayland FOUND_VAR Wayland_FOUND REQUIRED_VARS Wayland_LIBRARIES Wayland_INCLUDE_DIRS HANDLE_COMPONENTS)
