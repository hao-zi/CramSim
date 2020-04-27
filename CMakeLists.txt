cmake_minimum_required(VERSION 3.12)
project(CramSim CXX)

set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# add compiler warnings
add_compile_options(-Wall -Wextra -Wpedantic)
set(EXTRA_INCLUDES "")

# -------------------- SST CONFIGS --------------------
execute_process(
    COMMAND which sst-config
    OUTPUT_VARIABLE SST_CONFIG
    OUTPUT_STRIP_TRAILING_WHITESPACE
)
execute_process(
    COMMAND ${SST_CONFIG} --ELEMENT_CXXFLAGS
    OUTPUT_VARIABLE SST_FLAGS
    OUTPUT_STRIP_TRAILING_WHITESPACE
)
execute_process(
    COMMAND ${SST_CONFIG} --ELEMENT_LDFLAGS
    OUTPUT_VARIABLE SST_LDFLAGS
    OUTPUT_STRIP_TRAILING_WHITESPACE
)
separate_arguments(SST_FLAGS)
separate_arguments(SST_LDFLAGS)
execute_process(
    COMMAND which sst-register
    OUTPUT_VARIABLE SST_REGISTER
    OUTPUT_STRIP_TRAILING_WHITESPACE
)

macro(_sst_compile_link _name)
    if (TARGET ${_name})
        target_compile_definitions(${_name} PRIVATE)
        target_compile_options(${_name} PRIVATE ${SST_FLAGS} ${EXTRA_INCLUDES})
        target_link_options(${_name} PRIVATE ${SST_LDFLAGS})
        execute_process(COMMAND ${SST_REGISTER} ${CMAKE_PROJECT_NAME} ${CMAKE_PROJECT_NAME}_LIBDIR=${CMAKE_CURRENT_SOURCE_DIR})
    endif ()
endmacro()

add_custom_target(
    uninstall
    COMMAND ${SST_REGISTER} -u ${CMAKE_PROJECT_NAME}
    COMMAND ${CMAKE_COMMAND} --build . --target clean --config $<CONFIG>
)
# -------------------- SST CONFIGS --------------------

# -------------------- SST EXECUTABLES --------------------
set(
    SOURCES
    CramSim.cpp
    c_TraceFileReader.cpp
    c_Dimm.cpp
    c_Bank.cpp
    c_TxnConverter.cpp
    c_Transaction.cpp
    c_AddressHasher.cpp
    c_HashedAddress.cpp
    c_DeviceDriver.cpp
    c_Controller.cpp
    c_BankCommand.cpp
    c_BankStateActivating.cpp
    c_BankStateActive.cpp
    c_BankStateIdle.cpp
    c_BankStatePrecharge.cpp
    c_BankStateRead.cpp
    c_BankStateReadA.cpp
    c_BankStateRefresh.cpp
    c_BankStateWrite.cpp
    c_BankStateWriteA.cpp
    c_Rank.cpp
    c_Channel.cpp
    c_BankGroup.cpp
    c_BankInfo.cpp
    c_MemhBridge.cpp
    c_TxnScheduler.cpp
    c_CmdScheduler.cpp
    c_TxnDispatcher.cpp
    c_TxnGen.cpp
)

add_executable(
    lib${CMAKE_PROJECT_NAME}.so
    ${SOURCES}
)
_sst_compile_link(lib${CMAKE_PROJECT_NAME}.so)
# -------------------- SST EXECUTABLES --------------------
