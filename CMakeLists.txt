if(WIN32)
    # Windows default version
    cmake_minimum_required(VERSION 3.0)
else(WIN32)
    # Linux default cmake
    cmake_minimum_required(VERSION 2.8.6)
endif(WIN32)

# CMake module directory
set(CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/CMake ${CMAKE_MODULE_PATH})
include(Macros)

# Project name
project(CPROJECT C)

# Parse project version

# Gloabl include directory
include_directories(${CPROJECT_SOURCE_DIR}/include)

# Project deps options
option(CPROJECT_ENABLE_CJSON "enable cJSON libraries and package code" off)
option(CPROJECT_ENABLE_SQLITE3 "enable SQLite3 libraries and package code" off)
option(CPROJECT_ENABLE_OPENSSL "enable OpenSSL libraries and package code" off)
option(CPROJECT_ENABLE_XTSIGN "enable xtsign libraries and package code" off)
option(CPROJECT_ENABLE_CURL "enable cURL libraries and package code" off)

# Project output options
option(CPROJECT_BUILD_PROJECT "enable to build project, disable to build deps library" on)
option(CPROJECT_BUILD_PROJECT_SHARED  "enable to build project shared library" on)
option(CPROJECT_BUILD_PROJECT_STATIC  "enable to build project static library" off)

# Project compiler options
if(WIN32)
  option(CPROJECT_STATIC_CRT "Set to ON to build with static CRT on Windows (/MT)." off)
  option(ENABLE_INET_PTON "Set to OFF to prevent usage of inet_pton when building against modern SDKs while still requiring compatibility with older Windows versions, such as Windows XP, Windows Server 2003 etc." off)
  option(ENABLE_UNICODE "Set to ON to use the Unicode version of the Windows API functions" off)
  set(CPROJECT_TARGET_WINDOWS_VERSION "" CACHE STRING "Minimum target Windows version as hex string")
  if(CPROJECT_TARGET_WINDOWS_VERSION)
    add_definitions(-D_WIN32_WINNT=${CPROJECT_TARGET_WINDOWS_VERSION})
    set(CMAKE_REQUIRED_DEFINITIONS "${CMAKE_REQUIRED_DEFINITIONS} -D_WIN32_WINNT=${CPROJECT_TARGET_WINDOWS_VERSION}")
  elseif(ENABLE_INET_PTON)
    # _WIN32_WINNT_VISTA (0x0600)
    add_definitions(-D_WIN32_WINNT=0x0600)
    set(CMAKE_REQUIRED_DEFINITIONS "${CMAKE_REQUIRED_DEFINITIONS} -D_WIN32_WINNT=0x0600")
  else()
    # _WIN32_WINNT_WINXP (0x0501)
    add_definitions(-D_WIN32_WINNT=0x0501)
    set(CMAKE_REQUIRED_DEFINITIONS "${CMAKE_REQUIRED_DEFINITIONS} -D_WIN32_WINNT=0x0501")
  endif()
  if(ENABLE_UNICODE)
    add_definitions(-DUNICODE -D_UNICODE)
    if(MINGW)
      add_compile_options(-municode)
    endif()
  endif()
endif()

if(CMAKE_COMPILER_IS_GNUCC OR CMAKE_COMPILER_IS_CLANG)
  if(PICKY_COMPILER)
    foreach(_CCOPT -pedantic -Wall -W -Wpointer-arith -Wwrite-strings -Wunused -Wshadow -Winline -Wnested-externs -Wmissing-declarations -Wmissing-prototypes -Wfloat-equal -Wsign-compare -Wundef -Wendif-labels -Wstrict-prototypes -Wdeclaration-after-statement -Wstrict-aliasing=3 -Wcast-align -Wtype-limits -Wold-style-declaration -Wmissing-parameter-type -Wempty-body -Wclobbered -Wignored-qualifiers -Wconversion -Wvla -Wdouble-promotion)
      # surprisingly, CHECK_C_COMPILER_FLAG needs a new variable to store each new
      # test result in.
      string(MAKE_C_IDENTIFIER "OPT${_CCOPT}" _optvarname)
      check_c_compiler_flag(${_CCOPT} ${_optvarname})
      if(${_optvarname})
        set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${_CCOPT}")
      endif()
    endforeach()
    foreach(_CCOPT long-long multichar format-nonliteral sign-conversion system-headers pedantic-ms-format)
      # GCC only warns about unknown -Wno- options if there are also other diagnostic messages,
      # so test for the positive form instead
      string(MAKE_C_IDENTIFIER "OPT${_CCOPT}" _optvarname)
      check_c_compiler_flag("-W${_CCOPT}" ${_optvarname})
      if(${_optvarname})
        set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wno-${_CCOPT}")
      endif()
    endforeach()
  endif()
endif()

# Initialize CPROJECT_LIBS
set(CPROJECT_LIBS "")

if(CPROJECT_STATIC_CRT)
  set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")
  set(CMAKE_C_FLAGS_RELEASE "${CMAKE_C_FLAGS_RELEASE} /MT")
  set(CMAKE_C_FLAGS_DEBUG "${CMAKE_C_FLAGS_DEBUG} /MTd")
endif()

# Include all the necessary files for macros
include(CMakePushCheckState)
include(CheckFunctionExists)
include(CheckIncludeFile)
include(CheckIncludeFiles)
include(CheckLibraryExists)
include(CheckSymbolExists)
include(CheckTypeSize)
include(CheckCSourceCompiles)
include(CMakeDependentOption)
include(CheckCCompilerFlag)

# Compiler options
if(CMAKE_COMPILER_IS_GNUCC OR CMAKE_COMPILER_IS_CLANG)
  set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fPIC -g")
endif()

if(MSVC)
  # Disable default manifest added by CMake
  set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} /MANIFEST:NO")

  add_definitions(-D_CRT_SECURE_NO_DEPRECATE -D_CRT_NONSTDC_NO_DEPRECATE)
  if(CMAKE_C_FLAGS MATCHES "/W[0-4]")
    string(REGEX REPLACE "/W[0-4]" "/W4" CMAKE_C_FLAGS "${CMAKE_C_FLAGS}")
  else()
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} /W4")
  endif()

  # Use multithreaded compilation on VS 2008+
  if(MSVC_VERSION GREATER_EQUAL 1500)
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} /MP")
  endif()
endif()

# Depends thirparty library direcotry
set(DEPS_INSTALL_PREFIX ${CMAKE_CURRENT_LIST_DIR}/deps/${CMAKE_HOST_SYSTEM_NAME}/${CMAKE_HOST_SYSTEM_PROCESSOR}/${CMAKE_BUILD_TYPE}/)
set(CMAKE_PREFIX_PATH         ${DEPS_INSTALL_PREFIX} ${CMAKE_PREFIX_PATH})
set(CMAKE_SYSTEM_PREFIX_PATH  ${DEPS_INSTALL_PREFIX} ${CMAKE_SYSTEM_PREFIX_PATH})
set(CMAKE_LIBRARY_PATH        ${DEPS_INSTALL_PREFIX} ${CMAKE_LIBRARY_PATH})

# Install directory
set(CPROJECT_INSTALL_PREFIX "${CMAKE_CURRENT_LIST_DIR}/.bin/${CMAKE_HOST_SYSTEM_NAME}/${CMAKE_HOST_SYSTEM_PROCESSOR}")

# Source
if (CPROJECT_BUILD_PROJECT)
  # Source
  include(${CMAKE_CURRENT_LIST_DIR}/src/CMakeLists.txt)
  # Tests
  add_subdirectory(${CMAKE_CURRENT_LIST_DIR}/tests)
  # Demos
  add_subdirectory(${CMAKE_CURRENT_LIST_DIR}/demos)

else()
  # Depends
  add_subdirectory(${CMAKE_CURRENT_LIST_DIR}/deps)
endif()

