isec_aux_source_directory(${CMAKE_CURRENT_LIST_DIR} DEMOS_FILES)

foreach(demo_filepath ${DEMOS_FILES})
    STRING(REGEX REPLACE".+/(.+)\\..*""\\1" demo_file_name ${demo_filepath})
    add_executable(${demo_file_name} ${demo_file_name})
endforeach()
