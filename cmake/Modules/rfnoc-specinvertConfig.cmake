find_package(PkgConfig)
PKG_CHECK_MODULES(PC_RFNOC_SPECINVERT rfnoc-specinvert)

find_path(
    RFNOC_SPECINVERT_INCLUDE_DIRS
    NAMES rfnoc/specinvert/config.hpp
    HINTS $ENV{RFNOC_SPECINVERT_DIR}/include
        ${PC_RFNOC_SPECINVERT_INCLUDEDIR}
    PATHS ${CMAKE_INSTALL_PREFIX}/include
          /usr/local/include
          /usr/include
)

find_library(
    RFNOC_SPECINVERT_LIBRARIES
    NAMES rfnoc-specinvert
    HINTS $ENV{RFNOC_SPECINVERT_DIR}/lib
        ${PC_RFNOC_SPECINVERT_LIBDIR}
    PATHS ${CMAKE_INSTALL_PREFIX}/lib
          ${CMAKE_INSTALL_PREFIX}/lib64
          /usr/local/lib
          /usr/local/lib64
          /usr/lib
          /usr/lib64
          )

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(rfnoc-specinvert
    DEFAULT_MSG
    RFNOC_SPECINVERT_LIBRARIES
    RFNOC_SPECINVERT_INCLUDE_DIRS)
mark_as_advanced(
    RFNOC_SPECINVERT_LIBRARIES
    RFNOC_SPECINVERT_INCLUDE_DIRS)
