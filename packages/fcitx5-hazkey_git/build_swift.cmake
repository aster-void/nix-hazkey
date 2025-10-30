set(SWIFT_BUILD_TYPE "${SWIFT_BUILD_TYPE}")
set(SWIFT_EXECUTABLE "${SWIFT_EXECUTABLE}")
set(SWIFT_DETECTED_LIB_PATH "${SWIFT_DETECTED_LIB_PATH}")
set(SWIFT_LINK_PATH "${SWIFT_LINK_PATH}")
set(SWIFT_WORK_DIR "${SWIFT_WORK_DIR}")
set(LLAMA_STUB_DIR "${LLAMA_STUB_DIR}")

set(SWIFT_COMMAND
    ${SWIFT_EXECUTABLE} build -c ${SWIFT_BUILD_TYPE}
    --scratch-path=${CMAKE_CURRENT_BINARY_DIR}/swift-build
    -Xlinker -L${LLAMA_STUB_DIR}
)

if(SWIFT_DETECTED_LIB_PATH)
    list(APPEND SWIFT_COMMAND -Xlinker -L${SWIFT_DETECTED_LIB_PATH})
endif()

if(SWIFT_LINK_PATH)
    foreach(link_path ${SWIFT_LINK_PATH})
        list(APPEND SWIFT_COMMAND -Xlinker -L${link_path})
    endforeach()
endif()

if(DEFINED SWIFT_CC)
    set(_swift_cc "${SWIFT_CC}")
else()
    set(_swift_cc "${CMAKE_C_COMPILER}")
endif()

if(DEFINED SWIFT_CXX)
    set(_swift_cxx "${SWIFT_CXX}")
else()
    set(_swift_cxx "${CMAKE_CXX_COMPILER}")
endif()

set(ENV{CC} "${_swift_cc}")
set(ENV{CXX} "${_swift_cxx}")

if(DEFINED SWIFT_SDKROOT)
    set(ENV{SDKROOT} "${SWIFT_SDKROOT}")
endif()

set(ENV{CFLAGS} "$ENV{CFLAGS} -D__HAVE_FLOAT128=0 -D__HAVE_FLOAT64X=0")
set(ENV{CXXFLAGS} "$ENV{CXXFLAGS} -D__HAVE_FLOAT128=0 -D__HAVE_FLOAT64X=0")

if(DEFINED SWIFT_LIBRARY_PATH)
    if("$ENV{LIBRARY_PATH}" STREQUAL "")
        set(ENV{LIBRARY_PATH} "${SWIFT_LIBRARY_PATH}")
    else()
        set(ENV{LIBRARY_PATH} "${SWIFT_LIBRARY_PATH}:$ENV{LIBRARY_PATH}")
    endif()
    if("$ENV{LD_LIBRARY_PATH}" STREQUAL "")
        set(ENV{LD_LIBRARY_PATH} "${SWIFT_LIBRARY_PATH}")
    else()
        set(ENV{LD_LIBRARY_PATH} "${SWIFT_LIBRARY_PATH}:$ENV{LD_LIBRARY_PATH}")
    endif()
endif()

execute_process(
    COMMAND ${SWIFT_COMMAND}
    WORKING_DIRECTORY ${SWIFT_WORK_DIR}
    RESULT_VARIABLE result
)

if(NOT result EQUAL 0)
    execute_process(
        COMMAND ${SWIFT_COMMAND}
        WORKING_DIRECTORY ${SWIFT_WORK_DIR}
        RESULT_VARIABLE result2
    )
    if(NOT result2 EQUAL 0)
        message(FATAL_ERROR "Swift build failed after two attempts.")
    endif()
endif()
