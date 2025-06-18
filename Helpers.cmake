function(run_checks)
    cmake_parse_arguments(args "CHILD" "" "" "${ARGN}")

    if(args_CHILD)
        if(NOT PROJECT_NAME STREQUAL TOPMOST_PROJECT_NAME)
            message(FATAL_ERROR "This project requires its parent, ${TOPMOST_PROJECT_NAME}.")
        endif()
    else()
        set(TOPMOST_PROJECT_NAME "${PROJECT_NAME}" PARENT_SCOPE)
    endif()

    # We only support Linux. Everything else can go kick rocks.
    if(NOT UNIX OR APPLE)
        message(FATAL_ERROR "This operating system is not supported by ${PROJECT_NAME}.")
    endif()
endfunction()

function(create_target EXECUTABLE)
    set(SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/Source")
    file(GLOB SOURCES "${SOURCE_DIR}/*.c" "${SOURCE_DIR}/Targets/*.c")

    if(NOT ${EXECUTABLE})
        add_library(${PROJECT_NAME} ${SOURCES})
        set_target_properties(${PROJECT_NAME} PROPERTIES 
            VERSION ${PROJECT_VERSION}
            SOVERSION ${PROJECT_VERSION_MAJOR}
            PUBLIC_HEADER "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}.h"
        )
        # Copy the public interface into the build directory.
        file(COPY_FILE "${CMAKE_CURRENT_SOURCE_DIR}/Include/${PROJECT_NAME}.h" 
            "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}.h")
    else()
        add_executable(${PROJECT_NAME} ${SOURCES})
    endif()

    set_target_properties(${PROJECT_NAME} PROPERTIES             
        C_STANDARD 23
        C_STANDARD_REQUIRED ON
    )

    target_include_directories(${PROJECT_NAME} PUBLIC "${CMAKE_CURRENT_SOURCE_DIR}/Include")

    target_compile_options(${PROJECT_NAME} PRIVATE -Wall -Werror -Wpedantic -Wextra)
    if("${CMAKE_BUILD_TYPE}" STREQUAL "Debug")
        # https://cmake.org/cmake/help/latest/variable/CMAKE_EXPORT_COMPILE_COMMANDS.html
        set_target_properties(${PROJECT_NAME} PROPERTIES EXPORT_COMPILE_COMMANDS ON)

        target_compile_options(${PROJECT_NAME} PRIVATE -Og -g3 -ggdb -fsanitize=address 
            -fsanitize=pointer-compare  -fsanitize=leak -fsanitize=pointer-subtract 
            -fsanitize=undefined)
        target_link_options(${PROJECT_NAME} PRIVATE -fsanitize=address 
            -fsanitize=undefined)

        if(CMAKE_C_COMPILER_ID STREQUAL "GNU")
            # https://gcc.gnu.org/onlinedocs/gcc/Static-Analyzer-Options.html
            target_compile_options(${PROJECT_NAME} PRIVATE -fanalyzer)
        endif()
    else()
        # https://gcc.gnu.org/onlinedocs/gcc/x86-Options.html#index-march-15
        # https://gcc.gnu.org/onlinedocs/gcc/x86-Options.html#index-mtune-17
        target_compile_options(${PROJECT_NAME} PRIVATE -march=native -mtune=native 
            -Ofast -flto)
        target_link_options(${PROJECT_NAME} PRIVATE -Ofast -flto)
    endif()
endfunction()

function(link_external NAME)
    cmake_parse_arguments(PARSE_ARGV 1 args "" "" "COMPONENTS")

    if(NOT args_COMPONENTS)
        find_package(${NAME} REQUIRED)
        target_link_libraries(${PROJECT_NAME} ${${NAME}_LIBRARIES})
    else()    
        find_package(${NAME} REQUIRED COMPONENTS ${args_COMPONENTS})

        set(LINK_TARGETS ${${NAME}_LIBRARIES})
        foreach(component ${args_COMPONENTS})
            list(APPEND LINK_TARGETS ${component})
        endforeach()
        target_link_libraries(${PROJECT_NAME} PRIVATE ${LINK_TARGETS})
    endif()

    target_include_directories(${PROJECT_NAME} PRIVATE ${${NAME}_INCLUDE_DIRS})
endfunction()