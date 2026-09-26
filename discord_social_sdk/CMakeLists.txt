cmake_minimum_required(VERSION 3.21)
project(shiftline_discord_bridge LANGUAGES CXX)

if(NOT WIN32)
    message(FATAL_ERROR "The ShiftLine Discord bridge currently supports Windows only")
endif()

if(NOT CMAKE_SIZEOF_VOID_P EQUAL 8)
    message(FATAL_ERROR "The ShiftLine Discord bridge requires a Windows x64 toolchain")
endif()

set(DISCORD_PARTNER_LIBRARY "${CMAKE_CURRENT_LIST_DIR}/discord_partner_sdk.lib")
foreach(SDK_FILE discordpp.h cdiscord.h discord_partner_sdk.dll discord_krisp.dll)
    if(NOT EXISTS "${CMAKE_CURRENT_LIST_DIR}/${SDK_FILE}")
        message(FATAL_ERROR "Missing Discord Social SDK file: ${SDK_FILE}")
    endif()
endforeach()

if(NOT EXISTS "${DISCORD_PARTNER_LIBRARY}")
    message(FATAL_ERROR "Missing Discord Social SDK import library: discord_partner_sdk.lib")
endif()

add_library(shiftline_discord_bridge SHARED
    "${CMAKE_CURRENT_LIST_DIR}/../lib/discord_social_sdk_bridge.cpp")
target_compile_features(shiftline_discord_bridge PRIVATE cxx_std_17)
target_include_directories(shiftline_discord_bridge PRIVATE "${CMAKE_CURRENT_LIST_DIR}")
target_link_libraries(shiftline_discord_bridge PRIVATE "${DISCORD_PARTNER_LIBRARY}" Advapi32)
target_compile_definitions(shiftline_discord_bridge PRIVATE WIN32_LEAN_AND_MEAN NOMINMAX)
set_target_properties(shiftline_discord_bridge PROPERTIES
    PREFIX ""
    OUTPUT_NAME "shiftline_discord_bridge"
    RUNTIME_OUTPUT_DIRECTORY "${CMAKE_CURRENT_LIST_DIR}/..")

foreach(CONFIGURATION Debug Release RelWithDebInfo MinSizeRel)
    string(TOUPPER "${CONFIGURATION}" CONFIGURATION_UPPER)
    set_target_properties(shiftline_discord_bridge PROPERTIES
        "RUNTIME_OUTPUT_DIRECTORY_${CONFIGURATION_UPPER}" "${CMAKE_CURRENT_LIST_DIR}/..")
endforeach()

add_custom_command(TARGET shiftline_discord_bridge POST_BUILD
    COMMAND "${CMAKE_COMMAND}" -E copy_if_different
        "${CMAKE_CURRENT_LIST_DIR}/discord_partner_sdk.dll"
        "$<TARGET_FILE_DIR:shiftline_discord_bridge>"
    COMMAND "${CMAKE_COMMAND}" -E copy_if_different
        "${CMAKE_CURRENT_LIST_DIR}/discord_krisp.dll"
        "$<TARGET_FILE_DIR:shiftline_discord_bridge>")