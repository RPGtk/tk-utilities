#################################################################################
## A slight edit of the FindWaylandScanner.cmake file from the KDE 
## extra-cmake-modules repository on GitHub, taken at 15:47 on May 31st, 2024. 
## All rights reserved; copyrights are listed below.
#################################################################################

# SPDX-FileCopyrightText: 2012-2014 Pier Luigi Fiorini <pierluigi.fiorini@gmail.com>
#
# SPDX-License-Identifier: BSD-3-Clause

#[=======================================================================[.rst:
FindScanner
------------------

Try to find wayland-scanner.

If the wayland-scanner executable is not in your PATH, you can provide
an alternative name or full path location with the ``Scanner_EXECUTABLE``
variable.

This will define the following variables:

``Scanner_FOUND``
    True if wayland-scanner is available.

``Scanner_EXECUTABLE``
    The wayland-scanner executable.

If ``Scanner_FOUND`` is TRUE, it will also define the following imported
target:

``Wayland::Scanner``
    The wayland-scanner executable.

This module provides the following functions to generate C protocol
implementations:

  - ``ecm_add_wayland_client_protocol``
  - ``ecm_add_wayland_server_protocol``

::

  ecm_add_wayland_client_protocol(<target>
                                  PROTOCOL <xmlfile>
                                  BASENAME <basename>
                                  [PRIVATE_CODE])

  ecm_add_wayland_client_protocol(<source_files_var>
                                  PROTOCOL <xmlfile>
                                  BASENAME <basename>
                                  [PRIVATE_CODE])

Generate Wayland client protocol files from ``<xmlfile>`` XML
definition for the ``<basename>`` interface and append those files
to ``<source_files_var>`` or ``<target>``.

``PRIVATE_CODE`` instructs wayland-scanner to hide marshalling code
from the compiled DSO for use in other DSOs. The default is to
export this code.

::

  ecm_add_wayland_server_protocol(<target>
                                  PROTOCOL <xmlfile>
                                  BASENAME <basename>
                                  [PRIVATE_CODE])

  ecm_add_wayland_server_protocol(<source_files_var>
                                  PROTOCOL <xmlfile>
                                  BASENAME <basename>
                                  [PRIVATE_CODE])

Generate Wayland server protocol files from ``<xmlfile>`` XML
definition for the ``<basename>`` interface and append those files
to ``<source_files_var>`` or ``<target>``.

``PRIVATE_CODE`` instructs wayland-scanner to hide marshalling code
from the compiled DSO for use in other DSOs. The default is to
export this code.

Since 1.4.0.
#]=======================================================================]

include(${CMAKE_CURRENT_LIST_DIR}/Helpers.cmake)

# Find wayland-scanner
find_program(Scanner_EXECUTABLE NAMES wayland-scanner)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(Scanner
    FOUND_VAR
        Scanner_FOUND
    REQUIRED_VARS
        Scanner_EXECUTABLE
)

mark_as_advanced(Scanner_EXECUTABLE)

if(NOT TARGET Wayland::Scanner AND Scanner_FOUND)
    add_executable(Wayland::Scanner IMPORTED)
    set_target_properties(Wayland::Scanner PROPERTIES
        IMPORTED_LOCATION "${Scanner_EXECUTABLE}"
    )
endif()

include(FeatureSummary)
set_package_properties(Scanner PROPERTIES
    URL "https://wayland.freedesktop.org/"
    DESCRIPTION "Executable that converts XML protocol files to C code"
)

function(ecm_add_wayland_client_protocol target_or_sources_var)
    # Parse arguments
    set(options PRIVATE_CODE)
    set(oneValueArgs PROTOCOL BASENAME)
    cmake_parse_arguments(ARGS "${options}" "${oneValueArgs}" "" ${ARGN})

    if(ARGS_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "Unknown keywords given to ecm_add_wayland_client_protocol(): \"${ARGS_UNPARSED_ARGUMENTS}\"")
    endif()

    get_filename_component(_infile ${ARGS_PROTOCOL} ABSOLUTE)
    set(_client_header "${CMAKE_CURRENT_BINARY_DIR}/${ARGS_BASENAME}-protocol.h")
    set(_code "${CMAKE_CURRENT_BINARY_DIR}/${ARGS_BASENAME}-protocol.c")
    if(ARGS_PRIVATE_CODE)
        set(_code_type private-code)
    else()
        set(_code_type public-code)
    endif()

    set_source_files_properties(${_client_header} GENERATED)
    set_source_files_properties(${_code} GENERATED)
    set_property(SOURCE ${_client_header} ${_code} PROPERTY SKIP_AUTOMOC ON)

    add_custom_command(OUTPUT "${_client_header}"
        COMMAND ${Scanner_EXECUTABLE} client-header ${_infile} ${_client_header}
        DEPENDS ${_infile} VERBATIM)

    add_custom_command(OUTPUT "${_code}"
        COMMAND ${Scanner_EXECUTABLE} ${_code_type} ${_infile} ${_code}
        DEPENDS ${_infile} ${_client_header} VERBATIM)

    if (TARGET ${target_or_sources_var})
        target_sources(${target_or_sources_var} PRIVATE "${_client_header}" "${_code}")
    else()
        list(APPEND ${target_or_sources_var} "${_client_header}" "${_code}")
        set(${target_or_sources_var} ${${target_or_sources_var}} PARENT_SCOPE)
    endif()
endfunction()
